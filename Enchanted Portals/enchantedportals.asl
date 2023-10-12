state("EnchantedPortals-Win64-Shipping") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Enchanted Portals";
    // vars.Helper.StartFileLogger("Enchanted Portals.log");
    vars.Helper.Settings.CreateFromXml("Components/EnchantedPortals.Settings.xml");
    
    vars.S = (Func<object, string>)(v => v.GetType() == typeof(long) ? ("0x" + ((long)v).ToString("X")) : v.ToString());
    
    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + vars.S(oldValue) + " -> " + vars.S(currentValue));
    });
    
    vars.CompletedSplits = new HashSet<string>();

    vars.WorldEndLevels = new HashSet<string>() { "W1TO2", "W2TO3", "W3TO4", "W4TO5", "W5TO6" };

    vars.Helper.AlertLoadless();
}

init
{
    IntPtr FNamePool = vars.Helper.ScanRel(0xD, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15") + 0x10;
    IntPtr GWorld = vars.Helper.ScanRel(0x3, "48 8B 05 ?? ?? ?? ?? 48 3B C? 48 0F 44 C? 48 89 05 ?? ?? ?? ?? E8");
    vars.Log("FNamePool: " + FNamePool.ToString("X"));
    vars.Log("GWorld: " + GWorld.ToString("X"));

    vars.Watchers = new MemoryWatcherList
    {
         new MemoryWatcher<long>(new DeepPointer(GWorld, 0x18)) { Name = "worldFName" },

         new MemoryWatcher<bool>(new DeepPointer(GWorld, 0x118, 0x358)) { Name = "hasGameStarted" },

         new MemoryWatcher<long>(new DeepPointer(GWorld, 0x180)) { Name = "gameInstance" },
         new MemoryWatcher<bool>(new DeepPointer(GWorld, 0x180, 0x284)) { Name = "introWitch" },
         new MemoryWatcher<bool>(new DeepPointer(GWorld, 0x180, 0x28D)) { Name = "noPause" },
    
         new MemoryWatcher<long>(new DeepPointer(GWorld, 0x180, 0xF0)) { Name = "gissData" },
         new MemoryWatcher<int>(new DeepPointer(GWorld, 0x180, 0xF8)) { Name = "gissCount" },
         new MemoryWatcher<long>(new DeepPointer(GWorld, 0x30, 0xA8)) { Name = "actorData" },
         new MemoryWatcher<int>(new DeepPointer(GWorld, 0x30, 0xB0)) { Name = "actorCount" },
    };
    vars.SSWatchers = new MemoryWatcherList();
    vars.LAWatchers = new MemoryWatcherList();

    // The following code derefences FName structs to their string counterparts by
    // indexing the FNamePool table
    // `fname` is the actual struct, not a pointer to the struct
    var cachedFNames = new Dictionary<long, string>();
    vars.ReadFName = (Func<long, string>)(fname => 
    {
        string name;
        if (cachedFNames.TryGetValue(fname, out name))
            return name;

        int name_offset  = (int) fname & 0xFFFF;
        int chunk_offset = (int) (fname >> 0x10) & 0xFFFF;

        var base_ptr = new DeepPointer((IntPtr) FNamePool + chunk_offset * 0x8, name_offset * 0x2);
        byte[] name_metadata = base_ptr.DerefBytes(game, 2);

        // First 10 bits are the size, but we read the bytes out of order
        // e.g. 3C05 in memory is 0011 1100 0000 0101, but really the bytes we want are the last 8 and the first two, in that order.
        int size = name_metadata[1] << 2 | (name_metadata[0] & 0xC0) >> 6;

        // read the next (size) bytes after the name_metadata
        IntPtr name_addr;
        base_ptr.DerefOffsets(game, out name_addr);
        // 2 bytes here for the name_metadata
        name = game.ReadString(name_addr + 0x2, size);

        cachedFNames[fname] = name;
        return name;
    });

    vars.ReadFNameOfObject = (Func<IntPtr, string>)(obj => vars.ReadFName(game.ReadValue<long>(obj + 0x18)));

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key =>
    {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || !vars.CompletedSplits.Add(key)
        ) {
            return false;
        }

        vars.Log("Completed: " + key);
        return true;
    });

    vars.UpdateCurrent = (Action<IDictionary<string, object>, MemoryWatcherList>)((curr, watchers) =>
    {
        // just get all the watchers and chuck them into current
        foreach(var w in watchers)
        {
            curr[w.Name] = w.Current;
        }
    });

    vars.RefreshSubsystems = (Action<dynamic>)((curr) =>
    {
        print("Reloading subsystem cache...");
        vars.SSWatchers = new MemoryWatcherList();

        // iterate over game instances and check for the checkpoint trigger
        for (int i = 0; i < curr.gissCount; i++)
        {
            var ssPtr = game.ReadValue<IntPtr>((IntPtr) (curr.gissData + i * 0x18 + 0x8));
            var name = vars.ReadFNameOfObject(ssPtr);
            vars.Log("[S] " + name + " at " + ssPtr.ToString("X"));

            if (name == "LoadingScreenSubsystem") {
                vars.Watchers.Add(
                    new MemoryWatcher<long>(
                        new DeepPointer(ssPtr + 0x40)
                    ) { Name = "loadingWidget" }
                );
            }

        }
    });

    vars.RefreshActors = (Action<dynamic>)((curr) =>
    {
        print("Reloading actor cache...");
        vars.LAWatchers = new MemoryWatcherList();

        // iterate over game instances and check for the checkpoint trigger
        for (int i = 0; i < curr.actorCount; i++)
        {
            var aPtr = game.ReadValue<IntPtr>((IntPtr) (current.actorData + i * 0x8));
            var name = vars.ReadFNameOfObject(aPtr);
            vars.Log("[A] " + name + " at " + aPtr.ToString("X"));
        }        
    });

    vars.Watchers.UpdateAll(game);
    vars.UpdateCurrent(current, vars.Watchers);
    vars.RefreshSubsystems(current);
    vars.UpdateCurrent(current, vars.SSWatchers);
    vars.RefreshActors(current);
    vars.UpdateCurrent(current, vars.LAWatchers);
    vars.FirstGo = true;
}

update
{
    vars.Watchers.UpdateAll(game);
    vars.UpdateCurrent(current, vars.Watchers);

    if (old.gissCount != current.gissCount) vars.RefreshSubsystems(current);
    vars.UpdateCurrent(current, vars.SSWatchers);

    if (old.actorCount != current.actorCount) vars.RefreshActors(current);
    vars.UpdateCurrent(current, vars.LAWatchers);


    IDictionary<string, object> currentLookup = current;
    IDictionary<string, object> oldLookup = old;
    // Deref useful FNames here
    foreach (var key in new List<string>(currentLookup.Keys))
    {
        object value = currentLookup[key];

        if (!key.EndsWith("FName")) {
            if (vars.FirstGo) {
                vars.Log(key + ": " + vars.S(value));
            } else {
                vars.Watch(oldLookup, currentLookup, key);
            }
            continue;
        }
        
        // e.g. missionFName -> mission
        string newKey = key.Substring(0, key.Length - 5);
        string newName = vars.ReadFName((long) value);

        object oldName;
        bool newKeyExists = currentLookup.TryGetValue(newKey, out oldName);
        if (newName == "None" && newKeyExists)
            continue;
        
        // Debugging and such
        if (!newKeyExists)
        {
            vars.Log(newKey + ": " + newName);
        }
        else if (oldName != newName)
        {
            vars.Log(newKey + ": " + oldName + " -> " + newName);
        }

        currentLookup[newKey] = newName;
    }
    vars.FirstGo = false;
}

start
{
    return old.world == "MainMenu" && current.world == "INTROGAME";
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
}

split
{
    // level end
    if (old.world != current.world
     && current.world != "MainMenu"
     && vars.CheckSplit["level_" + old.world]
    ) {
        // note that "Libra" goes directly to MainMenu and
        // not a world transition level
        return true;
    }

    // TODO libro boss beat
}

isLoading
{
    // TODO some loading solution
    // return (current.noPause && current.world != "INTROGAME" && !current.introWitch) || current.gameInstance == 0;
}