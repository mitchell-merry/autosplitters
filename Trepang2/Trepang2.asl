state("CPPFPS-Win64-Shipping") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.GameName = "Trepang2";
	vars.Helper.Settings.CreateFromXml("Components/Trepang2.Settings.xml");
	vars.Helper.AlertLoadless();

    // these are the fname structs that we do not want to update if their current value is None
    vars.FNamesNoNone = new List<string>() { "missionFName" };
    // mission names to start timer on when entering from the safehouse
    vars.Missions = new List<string>() { "Mission_Prologue_C", "Mission_Mothman_C", "Mission_Cultists_C", "Mission_Ghosts_C", "Mission_HorizonHQ_C" };
}

init
{
    vars.finishedLoading = false;
    vars.Watchers = null;

    // basic ASL setup
    vars.CompletedSplits = new Dictionary<string, bool>();
    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || vars.CompletedSplits.ContainsKey(key) && vars.CompletedSplits[key]
        ) {
            return false;
        }

        vars.CompletedSplits[key] = true;
        vars.Log("Completed: " + key);
        return true;
    });

    #region UE introspection and property setup
    vars.GWorld = vars.Helper.ScanRel(8, "0F 2E ?? 74 ?? 48 8B 1D ?? ?? ?? ?? 48 85 DB 74");
    vars.Log("Found GWorld at 0x" + vars.GWorld.ToString("X"));
    vars.GEngine = vars.Helper.ScanRel(7, "A8 01 75 ?? 48 C7 05") + 0x4;
    vars.Log("Found GEngine at 0x" + vars.GEngine.ToString("X"));
    var FNamePool = vars.Helper.ScanRel(13, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15");
    vars.Log("Found FNamePool at 0x" + FNamePool.ToString("X"));

    // The following code derefences FName structs to their string counterparts by
    // indexing the FNamePool table

    // `fname` is the actual struct, not a pointer to the struct
    vars.CachedFNames = new Dictionary<long, string>();
    vars.ReadFName = (Func<long, string>)(fname => 
    {
        if (vars.CachedFNames.ContainsKey(fname)) return vars.CachedFNames[fname];

        int name_offset  = (int) fname & 0xFFFF;
        int chunk_offset = (int) (fname >> 0x10) & 0xFFFF;

        var base_ptr = new DeepPointer((IntPtr) FNamePool + chunk_offset * 0x8 + 0x10, name_offset * 0x2);
        byte[] name_metadata = base_ptr.DerefBytes(game, 2);

        // First 10 bits are the size, but we read the bytes out of order
        // e.g. 3C05 in memory is 0011 1100 0000 0101, but really the bytes we want are the last 8 and the first two, in that order.
        int size = name_metadata[1] << 2 | (name_metadata[0] & 0xC0) >> 6;

        // read the next (size) bytes after the name_metadata
        IntPtr name_addr;
        base_ptr.DerefOffsets(game, out name_addr);
        // 2 bytes here for the name_metadata
        string name = game.ReadString(name_addr + 0x2, size);

        vars.CachedFNames[fname] = name;
        return name;
    });

    // allow us to cancel operations if the game closes or livesplit shutdowns
    vars.cts = new CancellationTokenSource();
    System.Threading.Tasks.Task.Run((Func<System.Threading.Tasks.Task<object>>)(async () => {
        // Unfortunately, Trepang2 has multiple versions that are simultaneously actively used for runs
        // Between these versions, the offsets for various properties change
        // So even if we have a signature for GWorld and NamePoolData, the offsets will change, breaking this
        // between versions.
        // So we need to do some UE introspection to find the actual offsets in memory (the same way our dumper would)

        #region UE internal offsets
        // We cannot get these dynamically, so they are hardcoded
        // They will not change unless they were to switch to a significantly different version
        // of unreal engine, so this is unlikely to break
        var UOBJECT_CLASS = 0x10;
        var UOBJECT_NAME = 0x18;
        var UOBJECT_OUTER = 0x20;

        var UCLASS_SUPERSTRUCT = 0x40;
        var UCLASS_PROPERTYLINK = 0x50;

        var UPROPERTY_NAME = 0x28;
        var UPROPERTY_OFFSET = 0x4C;
        var UPROPERTY_PROPERTYLINKNEXT = 0x58;

        var UARRAYPROPERTY_INNER = 0x78;
        var UOBJECTPROPERTY_CLASS = 0x78;
        #endregion

        #region helper definitions
        Func<IntPtr, IntPtr> getObjectClass = (uobject =>
        {
            return vars.Helper.Read<IntPtr>(uobject + UOBJECT_CLASS);
        });

        Func<IntPtr, string> getObjectName = (uobject =>
        {
            return vars.ReadFName(vars.Helper.Read<long>(uobject + UOBJECT_NAME));
        });

        Func<IntPtr, IntPtr> getClassSuper = (uobject =>
        {
            return vars.Helper.Read<IntPtr>(uobject + UCLASS_SUPERSTRUCT);
        });

        // we want to, given a UClass, find the offset for `property` on that object
        // TODO: would be nice if we didn't have to traverse this multiple times if we wanted mutliple properties on the same class
        Func<IntPtr, string, IntPtr> getProperty = null;
        getProperty = ((uclass, propertyName) =>
        {
            IntPtr uproperty = vars.Helper.Read<IntPtr>(uclass + UCLASS_PROPERTYLINK);
            // Hack because I guess the propertylink can be null, but the superstruct will have it
            if (uproperty == IntPtr.Zero)
            {
                return getProperty(getClassSuper(uclass), propertyName);
            }

            while(uproperty != IntPtr.Zero)
            {
                var propName = vars.ReadFName(vars.Helper.Read<long>(uproperty + UPROPERTY_NAME));
                // vars.Log("  at " + propName);

                if (propName == propertyName)
                {
                    return uproperty;
                }

                uproperty = vars.Helper.Read<IntPtr>(uproperty + UPROPERTY_PROPERTYLINKNEXT);
            }

            throw new Exception("Couldn't find property " + propertyName + " in class 0x" + uclass.ToString("X"));
        });

        Func<IntPtr, IntPtr> getObjectPropertyClass = (uproperty =>
        {
            return vars.Helper.Read<IntPtr>(uproperty + UOBJECTPROPERTY_CLASS);
        });

        Func<IntPtr, IntPtr> getArrayPropertyInner = (uproperty =>
        {
            return getObjectPropertyClass(vars.Helper.Read<IntPtr>(uproperty + UARRAYPROPERTY_INNER));
        });

        Func<IntPtr, int> getPropertyOffset = (uproperty =>
        {
            return vars.Helper.Read<int>(uproperty + UPROPERTY_OFFSET);
        });
        
        /**
         * waitForPointer: unfortunately, sometimes we'll only know that a property holds a certain class,
         *   but the subproperty we want to look for only exists on a certain subclass of that class.
         * 
         * for example, we know that GEngine.GameInstance will always actually be a CPPFPSGameInstance,
         *   but the property for GameInstance will only claim that it is an instance of GameInstance (the class)
         *
         * in these cases, we want to wait until the actual uobject exists, and then we can read it's class
         *   from there (we can't just get it all from inspecting GEngine)
         *
         * waitForPointer takes a deeppointer and polls the value at that pointer until it is not null, and returns it
         */
        // Thanks apple! This is taken directly and modified slightly, though the rest of this code is still heavily inspired from
        // his borderlands 3 ASL
        // https://github.com/apple1417/Autosplitters/blob/69ad5a5959527a25880fd528e43d3342b1375dda/borderlands3.asl#L572C1-L590C19
        Func<DeepPointer, System.Threading.Tasks.Task<IntPtr>> waitForPointer = (async (deepPtr) =>
        {
            while (true) {
                try {
                    IntPtr dest = deepPtr.Deref<IntPtr>(game);
                    if (dest != IntPtr.Zero) {
                        return dest;
                    }
                } catch (ArgumentException) { continue; }

                await System.Threading.Tasks.Task.Delay(
                    500, vars.cts.Token
                ).ConfigureAwait(true);
                vars.cts.Token.ThrowIfCancellationRequested();
            }
        });
        #endregion
        
        try {
            #region reading properties and offsets
            var GEngine = await waitForPointer(new DeepPointer(vars.GEngine));
            vars.Log("GEngine at: " + GEngine.ToString("X"));

            IntPtr GameEngine = getObjectClass(GEngine);
            vars.Log("GameEngine at: " + GameEngine.ToString("X"));
            var GameEngine_GameInstance = getProperty(GameEngine, "GameInstance");
            var GameEngine_GameInstance_Offset = getPropertyOffset(GameEngine_GameInstance);
            vars.Log("GameInstance Offset: " + GameEngine_GameInstance_Offset.ToString("X"));

            var CPPFPSGameInstance = await waitForPointer(new DeepPointer(
                vars.GEngine,
                GameEngine_GameInstance_Offset
            ));
            var CPPFPSGameInstance_Class = getObjectClass(CPPFPSGameInstance);
            
            var CPPFPSGameInstance_CurrentMissionInfoObject = getProperty(CPPFPSGameInstance_Class, "CurrentMissionInfoObject");
            var CPPFPSGameInstance_CurrentMissionInfoObject_Offset = getPropertyOffset(CPPFPSGameInstance_CurrentMissionInfoObject);
            vars.Log("CurrentMissionInfoObject Offset: " + CPPFPSGameInstance_CurrentMissionInfoObject_Offset.ToString("X"));

            var CPPFPSGameInstance_CurrentLoadingWidget = getProperty(CPPFPSGameInstance_Class, "CurrentLoadingWidget");
            var CPPFPSGameInstance_CurrentLoadingWidget_Offset = getPropertyOffset(CPPFPSGameInstance_CurrentLoadingWidget);
            vars.Log("CurrentLoadingWidget Offset: " + CPPFPSGameInstance_CurrentLoadingWidget_Offset.ToString("X"));

            var GameInstance_LocalPlayers = getProperty(getObjectPropertyClass(GameEngine_GameInstance), "LocalPlayers");
            var GameInstance_LocalPlayers_Offset = getPropertyOffset(GameInstance_LocalPlayers);
            vars.Log("LocalPlayers Offset: " + GameInstance_LocalPlayers_Offset.ToString("X"));

            var LocalPlayer_PlayerController = getProperty(getArrayPropertyInner(GameInstance_LocalPlayers), "PlayerController");
            var LocalPlayer_PlayerController_Offset = getPropertyOffset(LocalPlayer_PlayerController);
            vars.Log("PlayerController Offset: " + LocalPlayer_PlayerController_Offset.ToString("X"));
            
            var playerController = await waitForPointer(new DeepPointer(
                vars.GEngine,
                GameEngine_GameInstance_Offset,
                GameInstance_LocalPlayers_Offset,
                0x0,
                LocalPlayer_PlayerController_Offset
            ));

            vars.Log("found PlayerController: " + playerController.ToString("X"));
            var PlayerControllerBP_C = getObjectClass(playerController);
            var PlayerControllerBP_C_MyPlayer = getProperty(PlayerControllerBP_C, "MyPlayer");
            var PlayerControllerBP_C_MyPlayer_Offset = getPropertyOffset(PlayerControllerBP_C_MyPlayer);
            vars.Log("MyPlayer Offset: " + PlayerControllerBP_C_MyPlayer_Offset.ToString("X"));

            var PlayerBP_C_bIsWearingGasMask = getProperty(getObjectPropertyClass(PlayerControllerBP_C_MyPlayer), "bIsWearingGasMask");
            var PlayerBP_C_bIsWearingGasMask_Offset = getPropertyOffset(PlayerBP_C_bIsWearingGasMask);
            vars.Log("bIsWearingGasMask Offset: " + PlayerBP_C_bIsWearingGasMask_Offset.ToString("X"));

            var PlayerBP_C_IsUnlockingRestraints = getProperty(getObjectPropertyClass(PlayerControllerBP_C_MyPlayer), "IsUnlockingRestraints");
            var PlayerBP_C_IsUnlockingRestraints_Offset = getPropertyOffset(PlayerBP_C_IsUnlockingRestraints);
            vars.Log("IsUnlockingRestraints Offset: " + PlayerBP_C_IsUnlockingRestraints_Offset.ToString("X"));
            
            IntPtr UWorld = getObjectClass(vars.Helper.Read<IntPtr>(vars.GWorld));
            vars.Log("UWorld at: " + UWorld.ToString("X"));
            
            var UWorld_AuthorityGameMode = getProperty(UWorld, "AuthorityGameMode");
            var UWorld_AuthorityGameMode_Offset = getPropertyOffset(UWorld_AuthorityGameMode);
            vars.Log("AuthorityGameMode Offset: " + UWorld_AuthorityGameMode_Offset.ToString("X"));

            var GameMode = await waitForPointer(new DeepPointer(
                vars.GWorld,
                UWorld_AuthorityGameMode_Offset
            ));

            var ABaseGameMode_C = getObjectClass(GameMode);
            vars.Log(getObjectName(ABaseGameMode_C) + " at " + GameMode.ToString("X"));

            var ABaseGameMode_C_CurrentCutscene = getProperty(ABaseGameMode_C, "CurrentCutscene");
            var ABaseGameMode_C_CurrentCutscene_Offset = getPropertyOffset(ABaseGameMode_C_CurrentCutscene);
            vars.Log("CurrentCutscene Offset: " + ABaseGameMode_C_CurrentCutscene_Offset.ToString("X"));

            var ABaseGameMode_C_AllLiveBaseChars = getProperty(ABaseGameMode_C, "AllLiveBaseChars");
            var ABaseGameMode_C_AllLiveBaseCharsArrayPtr_Offset = getPropertyOffset(ABaseGameMode_C_AllLiveBaseChars);
            vars.Log("AllLiveBaseCharsArrayPtr Offset: " + ABaseGameMode_C_AllLiveBaseCharsArrayPtr_Offset.ToString("X"));
            var ABaseGameMode_C_AllLiveBaseCharsArrayCount_Offset = getPropertyOffset(ABaseGameMode_C_AllLiveBaseChars) + 8;
            vars.Log("AllLiveBaseCharsArrayCount Offset: " + ABaseGameMode_C_AllLiveBaseCharsArrayCount_Offset.ToString("X"));

            #endregion

            #region creating the memorywatchers
            vars.Watchers = new MemoryWatcherList() {
                // we automatically deref this to their name without FName in update {}
                // e.g. we can access current.mission directly
                new MemoryWatcher<long>(
                   new DeepPointer(
                        vars.GWorld,
                        UWorld_AuthorityGameMode_Offset,
                        ABaseGameMode_C_CurrentCutscene_Offset,
                        UOBJECT_OUTER,
                        UOBJECT_NAME
                    )
                ) { Name = "cutsceneFName" },
                new MemoryWatcher<IntPtr>(
                   new DeepPointer(
                        vars.GWorld,
                        UWorld_AuthorityGameMode_Offset,
                        ABaseGameMode_C_AllLiveBaseCharsArrayPtr_Offset
                    )
                ) { Name = "liveBaseCharsArrayPtr" },
                new MemoryWatcher<int>(
                   new DeepPointer(
                        vars.GWorld,
                        UWorld_AuthorityGameMode_Offset,
                        ABaseGameMode_C_AllLiveBaseCharsArrayCount_Offset
                    )
                ) { Name = "liveBaseCharsArrayCount" },
                new MemoryWatcher<long>(
                   new DeepPointer(
                        vars.GEngine,
                        GameEngine_GameInstance_Offset,
                        CPPFPSGameInstance_CurrentMissionInfoObject_Offset,
                        UOBJECT_NAME
                    )
                ) { Name = "missionFName" },

                // Other fun things
                new MemoryWatcher<bool>(
                   new DeepPointer(
                        vars.GEngine,
                        GameEngine_GameInstance_Offset,
                        GameInstance_LocalPlayers_Offset,
                        0x0,
                        LocalPlayer_PlayerController_Offset,
                        PlayerControllerBP_C_MyPlayer_Offset,
                        PlayerBP_C_bIsWearingGasMask_Offset
                    )
                ) { Name = "IsWearingGasMask" },
                new MemoryWatcher<bool>(
                   new DeepPointer(
                        vars.GEngine,
                        GameEngine_GameInstance_Offset,
                        GameInstance_LocalPlayers_Offset,
                        0x0,
                        LocalPlayer_PlayerController_Offset,
                        PlayerControllerBP_C_MyPlayer_Offset,
                        PlayerBP_C_IsUnlockingRestraints_Offset
                    )
                ) { Name = "IsUnlockingRestraints" },

                // pointer to the LoadingWidget - if we are in a loading screen, then this is set
                // so, we just check if it is set
                new MemoryWatcher<IntPtr>(
                   new DeepPointer(
                        vars.GEngine,
                        GameEngine_GameInstance_Offset,
                        CPPFPSGameInstance_CurrentLoadingWidget_Offset
                    )
                ) { Name = "LoadingWidget" },
            };
            #endregion
        } catch (Exception e) {
            vars.Log("error: " + e);
            throw;
        }

        vars.finishedLoading = true;
        return;
    }), vars.cts.Token);
    #endregion
}

update
{
    if (!vars.finishedLoading)
    {
        // still loading offsets and creating memorywatchers - see init {}
        return;
    }

    IDictionary<string, object> currdict = current;
    
    // read the values, place them all in current
    vars.Watchers.UpdateAll(game);
    foreach (var watcher in vars.Watchers)
    {
        currdict[watcher.Name] = watcher.Current;
    }

    // This is useful for more than just the isLoading {} block
    current.isLoading = current.LoadingWidget != IntPtr.Zero || current.missionFName == 0;

    // this will get properly set after we've resolved the mission name
    current.hordeMode = false;

    if (!((IDictionary<string, object>)(old)).ContainsKey("cutsceneFName"))
    {
        vars.Log("Loaded values:");
        vars.Log("  cutsceneFName: " + current.cutsceneFName.ToString("X"));
        vars.Log("  liveBaseCharsArrayPtr: " + current.liveBaseCharsArrayPtr.ToString("X"));
        vars.Log("  liveBaseCharsArrayCount: " + current.liveBaseCharsArrayCount);
        vars.Log("  missionFName: " + current.missionFName.ToString("X"));
        vars.Log("  IsUnlockingRestraints: " + current.IsUnlockingRestraints);
        vars.Log("  IsWearingGasMask: " + current.IsWearingGasMask);
        vars.Log("  LoadingWidget: " + current.LoadingWidget.ToString("X"));
        vars.Log("  isLoading: " + current.isLoading);
        return;
    }

    if (old.isLoading != current.isLoading)
    {
        vars.Log("isLoading: " + old.isLoading + " -> " + current.isLoading);
    }

    // Deref useful FNames here - any key in current that ends with FName will be read and transformed
    // into the corresponding string
    foreach (var fname in new List<string>(currdict.Keys))
    {
        if (!fname.EndsWith("FName"))
            continue;
        
        var key = fname.Substring(0, fname.Length-5);
        // We get nicer splits if we split on loading screens for mission changes
        if (key == "mission" && currdict.ContainsKey(key) && !current.isLoading)
            continue;

        var val = vars.ReadFName((long)currdict[fname]);
        // e.g. missionFName -> mission
        if (val == "None" && vars.FNamesNoNone.Contains(fname) && currdict.ContainsKey(key))
            continue;

        // Debugging and such
        if (!currdict.ContainsKey(key))
        {
            vars.Log(key + ": " + val);
        }
        else if (currdict[key] != val)
        {
            vars.Log(key + ": " + currdict[key] + " -> " + val);
        }

        currdict[key] = val;
    }

    // we'll enable horde mode logic only when requested
    current.hordeMode = settings["combat_sim_waves"] && current.mission.StartsWith("Mission_Horde_");

    if (old.hordeMode != current.hordeMode)
    {
        vars.Log("  hordeMode: " + current.hordeMode);
    }

    // Note: The following code works properly only in horde mode. But
    // we'll add dummy values outside horde mode to keep transitions
    // sane.
    bool playerAlive = false;
    List<string> enemies = new List<string>();
    List<string> friends = new List<string>();

    if (current.hordeMode)
    {
        // In full log output mode, read the currently alive
        // characters and classify them as:
        // - playerAlive
        // - friends
        // - enemies
        // This is useful only for debugging.
        //
        // Otherwise, we'll short circuit as soon as we find the
        // player and two enemies. One enemy would be enough for the
        // start/split logic. Two enemies allows us to still log
        // useful info on 2 -> 1 transition in case friends are
        // incorrectly classified as enemies.
        bool fullOutput = false;

        for (int i = 0; i < current.liveBaseCharsArrayCount; ++i)
        {
            var c = vars.Helper.Read<IntPtr>(current.liveBaseCharsArrayPtr + i*8);
            if (c != null)
            {
                var UOBJECT_NAME = 0x18;
                var charName = vars.ReadFName(vars.Helper.Read<long>(c + UOBJECT_NAME));

                // classify the character by name
                if (charName == "PlayerBP")
                {
                    playerAlive = true;
                }
                else if (charName.StartsWith("NPC_Merc_HordeSquadmate"))
                {
                    if (fullOutput)
                        friends.Add(charName);
                }
                else
                {
                    enemies.Add(charName);
                }

                // short circuit?
                if (!fullOutput && playerAlive && enemies.Count >= 2)
                    break;
            }
        }
    }

    current.playerAlive = playerAlive;
    current.enemies = enemies;
    current.friends = friends;

    if (current.hordeMode)
    {
        if (!old.hordeMode || old.liveBaseCharsArrayCount != current.liveBaseCharsArrayCount)
        {
            vars.Log("  liveBaseCharsArrayCount: " + current.liveBaseCharsArrayCount);
        }

        if (!old.hordeMode || (old.playerAlive != current.playerAlive))
        {
            vars.Log("  Player alive: " + current.playerAlive);
        }

        if (!old.hordeMode || (old.friends.Count != current.friends.Count))
        {
            vars.Log("  Friends: " + String.Join(" ", current.friends));
        }

        if (!old.hordeMode || (old.enemies.Count != current.enemies.Count))
        {
            vars.Log("  Enemies: " + String.Join(" ", current.enemies));
        }
    }
}

onStart
{
    // This makes sure the timer always starts at 0.00
    timer.IsGameTimePaused = true;
    
    // refresh all splits when we start the game, none are yet completed
    vars.CompletedSplits = new Dictionary<string, bool>();
}

start
{
    if (!((IDictionary<string, object>)(old)).ContainsKey("mission"))
        return false;

    if (settings["start_on_mission"]
     && old.isLoading
     && !current.isLoading
     && vars.Missions.Contains(current.mission)
    ) {
        return true;
    }

    // trigger start when a wave spawns in
    if (settings["combat_sim_waves"]
        && old.hordeMode
        && current.hordeMode
        && current.playerAlive
        && old.enemies.Count == 0
        && current.enemies.Count > 0)
    {
        return true;
    }

    return old.cutscene == "None" && current.cutscene == "Prologue_Intro_SequencePrologue_Intro_Master";
}

isLoading
{
    return current.isLoading;
}

split
{
    if (!((IDictionary<string, object>)(old)).ContainsKey("mission"))
        return false;

    if (!old.IsUnlockingRestraints &&
        current.IsUnlockingRestraints &&
        vars.CheckSplit("Mission_Prologue_C__restraints")
    ) {
        return true;
    }

    if (old.IsWearingGasMask &&
        !current.IsWearingGasMask &&
        current.mission == "Mission_Ghosts_C" &&
        !current.isLoading &&
        vars.CheckSplit("Mission_Ghosts_C__gasmask")
    ) {
        return true;
    }

    if (old.mission != current.mission)
    {
        if (old.mission == "Mission_Safehouse_C")
        {
            return vars.CheckSplit(current.mission + "__enter");
        }
     
        if (current.mission == "Mission_Safehouse_C"
        || (current.mission == "Mission_FrontEnd_C" && old.mission == "Mission_SyndicateHQFinal_C")
        ) {
            return vars.CheckSplit(old.mission + "__exit");
        }
    }

    if (old.cutscene == "None" && old.cutscene != current.cutscene)
    {
        return vars.CheckSplit(current.cutscene);
    }

    // Trigger a split when the last enemy has died but only if the
    // player is still alive and we're not loading
    //
    // NOTE: It would be better to detect splits using
    // HordeModeActor2::CurrentWaveIndex, but this would require figuring
    // out how to find that object.
    if (settings["combat_sim_waves"]
        && old.hordeMode               // make sure we don't trigger on transitions such as checkpoint reloads
        && current.hordeMode
        && current.playerAlive
        && !current.isLoading
        && old.enemies.Count > 0
        && current.enemies.Count == 0)
    {
        return true;
    }
}

exit
{
    vars.cts.Cancel();
    timer.IsGameTimePaused = true;
}

shutdown
{
    vars.cts.Cancel();
}
