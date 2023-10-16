state("Pandemic") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "SCP: 5K";
    vars.Helper.Settings.CreateFromXml("Components/SCP5K.Settings.xml");
    // vars.Helper.StartFileLogger("SCP5K.log");
    
    vars.CompletedSplits = new HashSet<string>();
    
    // vars.Helper.AlertLoadless();
}

init
{
    IntPtr GWorld = vars.Helper.ScanRel(0x3, "48 8B 05 ?? ?? ?? ?? 48 3B C? 48 0F 44 C? 48 89 05 ?? ?? ?? ?? E8");
    IntPtr FNamePool = vars.Helper.ScanRel(13, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15") + 0x10;
    vars.Log("FNamePool: " + FNamePool.ToString("X"));
    vars.Log("GWorld: " + GWorld.ToString("X"));

    vars.Watchers = new MemoryWatcherList
    {
        new MemoryWatcher<long>(GWorld) { Name = "GWorld" },
        new MemoryWatcher<long>(new DeepPointer(GWorld, 0x18)) { Name = "worldFName" },

        // world -> GameState -> Class -> FName
        new MemoryWatcher<long>(new DeepPointer(GWorld, 0x120, 0x10, 0x18)) { Name = "GSClassFName" },
        // GS_PandemicGameState_C-only fields
        // world -> GameState -> GameStatus
        new MemoryWatcher<byte>(new DeepPointer(GWorld, 0x120, 0x304)) { Name = "GameStatus" },

        // world -> Level -> WorldSettings -> ObjectiveManager -> Objectives.Data
        new MemoryWatcher<long>(new DeepPointer(GWorld, 0x30, 0x258, 0x3F0, 0x220)) { Name = "objData" },
        new MemoryWatcher<int>(new DeepPointer(GWorld, 0x30, 0x258, 0x3F0, 0x228)) { Name = "objCount" },
    };
    
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

    vars.ReadFNameOfObject = (Func<IntPtr, string>)(obj => 
    {
        return vars.ReadFName(game.ReadValue<long>(obj + 0x18));
    });

    // read a UObjective into a dynamic object
    // objAddr is the address of the objective
    vars.ReadObjective = (Func<IntPtr, dynamic>)(objAddr =>
    {
        dynamic ret = new ExpandoObject();

        // ret.Name = vars.ReadFName(vars.Helper.Read<long>(objAddr + 0x40));
        // ret.Major = vars.Helper.Read<bool>(objAddr + 0x78);
        // ret.Active = vars.Helper.Read<bool>(objAddr + 0x38);
        // ret.Started = vars.Helper.Read<bool>(objAddr + 0x39);
        ret.Completed = vars.Helper.Read<bool>(objAddr + 0x3B);
        // ret.Succeeded = vars.Helper.Read<bool>(objAddr + 0x3C);
        // ret.DisplayOnUI = vars.Helper.Read<bool>(objAddr + 0x3D);

        return ret;
    });

    vars.CheckSetting = (Func<string, bool>)(key => settings.ContainsKey(key) && settings[key]);

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key =>
    {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!vars.CheckSetting(key) || !vars.CompletedSplits.Add(key)
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

    vars.Watchers.UpdateAll(game);
    vars.UpdateCurrent(current, vars.Watchers);
}

update
{
    vars.Watchers.UpdateAll(game);
    vars.UpdateCurrent(current, vars.Watchers);

    // Deref useful FNames here
    IDictionary<string, object> currentLookup = current;
    foreach (var key in new List<string>(currentLookup.Keys))
    {
        object value = currentLookup[key];

        if (!key.EndsWith("FName") || value.GetType() != typeof(long))
            continue;
        
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

    if (old.GameStatus != current.GameStatus) vars.Log(current.GameStatus);
}

start
{
    return current.GSClass == "GS_PandemicGameState_C"
        && old.GameStatus == 1 && current.GameStatus == 2;
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
}

split
{
    if (vars.CheckSetting("obj"))
    {
        for (var i = 0; i < current.objCount; i++) {
            var key = "obj_" + current.world + "_" + i;
            if (!vars.CheckSetting(key)) continue;

            var objAddr = vars.Helper.Read<IntPtr>((IntPtr) current.objData + 0x8 * i);
            var obj = vars.ReadObjective(objAddr);
            
            if (obj.Completed && vars.CheckSplit(key))
            {
                return true;
            }
        }
    }
}

isLoading
{
    return current.GWorld == 0 || current.world == "TransitionMap"
        || current.world == "EntryLevel" || current.GSClass == "GameStateBase"
        || (current.GSClass == "GS_PandemicGameState_C" && current.GameStatus == 1);
}