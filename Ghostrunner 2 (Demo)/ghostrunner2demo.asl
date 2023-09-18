state("Ghostrunner2-Win64-Shipping")
{
    long FNamePool: 0x67FADE8;
    long worldFName: 0x6A3BCB0, 0x18;

    long giss: 0x6A3BCB0, 0x180, 0xF0;
    int gissCount: 0x6A3BCB0, 0x180, 0xF8;

    float StartTime: 0x6A3BCB0, 0x118, 0x3A4;
    float PrevTime: 0x6A3BCB0, 0x118, 0x3A8;
    float CurrTime: 0x6A3BCB0, 0x118, 0x3AC;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Ghostrunner 2 (Demo)";
    vars.Helper.Settings.CreateFromXml("Components/Ghostrunner2Demo.Settings.xml");
    
    vars.S = (Func<object, string>)(v => v.GetType() == typeof(long) ? ("0x" + ((long)v).ToString("X")) : v.ToString());

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + vars.S(oldValue) + " -> " + vars.S(currentValue));
    });
    
    
    vars.CompletedSplits = new HashSet<string>();
    
    vars.Helper.AlertGameTime();
}

init
{
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

        var base_ptr = new DeepPointer((IntPtr) current.FNamePool + chunk_offset * 0x8, name_offset * 0x2);
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

    vars.RefreshSubsystemCache = (Action<dynamic>)((curr) =>
    {
        print("Reloading subsystem cache...");
        vars.Checkpoint = null;

        // iterate over game instances and check for the checkpoint trigger
        for (int i = 0; i < curr.gissCount; i++)
        {
            var ssPtr = game.ReadValue<IntPtr>((IntPtr) (curr.giss + i * 0x18 + 0x8));
            var name = vars.ReadFNameOfObject(ssPtr);

            if (name == "CheckpointSubsystem") {
                vars.Checkpoint = new MemoryWatcher<long>(new DeepPointer(ssPtr + 0x50, 0x18));
            }

        }
    });

    vars.RefreshSubsystemCache(current);
    vars.First = true;
    vars.TotalTime = 0f;
}

update
{
    if (old.gissCount == 0 && current.gissCount != 0)
    {
        vars.RefreshSubsystemCache(current);
    }

    vars.Checkpoint.Update(game);
    current.checkpointFName = vars.Checkpoint != null ? vars.Checkpoint.Current : 0;

    // Deref useful FNames here
    IDictionary<string, object> currentLookup = current;
    foreach (var key in new List<string>(currentLookup.Keys))
    {
        object value = currentLookup[key];

        if (!key.EndsWith("FName"))
        {
            // if (vars.First)
            //     vars.Log(key + ": " + vars.S(value));
            // else if (key != "CurrTime")
            //     vars.Watch(old, current, key);

            continue;
        }
        
        // e.g. missionFName -> mission
        string newKey = key.Substring(0, key.Length - 5);
        string newName = vars.ReadFName((long) value);

        object oldName;
        bool newKeyExists = currentLookup.TryGetValue(newKey, out oldName);
        
        // Debugging and such
        if (!newKeyExists)
            vars.Log(newKey + ": " + newName);
        else if (oldName != newName)
            vars.Log(newKey + ": " + oldName + " -> " + newName);

        currentLookup[newKey] = newName;
    }

    // bleh...
    if (old.PrevTime < current.PrevTime) current.CurrTime = 0;
    // don't update time between worlds (goes to 0)
    if (current.world == "None" || current.checkpoint == "None")
    {
        current.CurrTime = old.CurrTime;
        current.PrevTime = old.PrevTime;
    }

    vars.First = false;
}


start
{
    return current.world == "VSL_01_World"
        && old.StartTime == 0 && current.StartTime > old.StartTime;
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
    vars.TotalTime = 0f;
}

split
{
    return old.checkpoint != current.checkpoint && vars.CheckSplit("cp_" + current.world + "_" + current.checkpoint);
}

gameTime
{
    // TODO fix transition between worlds
    var timeToAdd = current.CurrTime + current.PrevTime;
    return TimeSpan.FromSeconds(vars.TotalTime + timeToAdd);
}

isLoading
{
    return !(current.world == "None" || current.checkpoint == "None");
}