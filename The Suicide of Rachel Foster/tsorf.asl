state("Overlook-Win64-Shipping")
{
    long FNamePool: 0x41D9240;

    long arrayOfObjects: 0x4448200, 0x30, 0x98;
    int arrayCount: 0x4448200, 0x30, 0xA0;

    long worldFName: 0x4448200, 0x20, 0x18;
    long levelFName: 0x4448200, 0x30, 0xE8, 0x120, 0x0, 0x18;
    // long thingFName: 0x4448200, 0x30, 0x318, 0x10, 0x18;
}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.GameName = "TSORF";
    vars.Helper.Settings.CreateFromXml("Components/TSORF.Settings.xml");
	vars.Helper.AlertLoadless();
}

init
{
    // The following code derefences FName structs to their string counterparts by
    // indexing the FNamePool table

    // `fname` is the actual struct, not a pointer to the struct
    vars.CachedFNames = new Dictionary<long, string>();
    vars.ReadFName = (Func<long, string>)(fname => 
    {
        if (vars.CachedFNames.ContainsKey(fname)) return vars.CachedFNames[fname];

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
        string name = game.ReadString(name_addr + 0x2, size);

        vars.CachedFNames[fname] = name;
        return name;
    });

    vars.ReadFNameOfObject = (Func<IntPtr, string>)(obj => 
    {
        return vars.ReadFName(game.ReadValue<long>(obj + 0x18));
    });

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
}

update
{
    // Deref useful FNames here
    IDictionary<string, object> currdict = current;
    foreach (var fname in new List<string>(currdict.Keys))
    {
        if (!fname.EndsWith("FName"))
            continue;
        
        var key = fname.Substring(0, fname.Length-5);

        var val = vars.ReadFName((long)currdict[fname]);
        // e.g. missionFName -> mission
        if (val == "None" && currdict.ContainsKey(key))
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
    
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits = new Dictionary<string, bool>();
    vars.Log("count: " + current.arrayCount);
    for (int i = 0; i < current.arrayCount; i++)
    {
        var actorPtr = game.ReadValue<IntPtr>((IntPtr) (current.arrayOfObjects + i * 0x8));
        var fname = game.ReadValue<long>(actorPtr + 0x18);
        var actorName = vars.ReadFName(fname);

        if (actorName != "BP_LevelLoader")
            continue; // gtfo nobody cares about you

        vars.Log(actorName);
        
        var GameManagerReference = game.ReadValue<IntPtr>(actorPtr + 0x298);
        vars.Log("--GameManagerReference: " + GameManagerReference.ToString("X")); 
        vars.Log("----Name: " + vars.ReadFNameOfObject(GameManagerReference));

        var ObjectivesText = game.ReadValue<IntPtr>(GameManagerReference + 0x400);
        var ObjectivesTextCount = game.ReadValue<int>(GameManagerReference + 0x408);
        // TMap:
        // A TArray of structs where 0x0 in each struct is key, 0x8 is value, and the size of the struct is 0x28 
        
        for (int obj = 0; obj < ObjectivesTextCount; obj++)
        {
            var ObjectiveEnum = game.ReadValue<int>(ObjectivesText + 0x28 * obj);
            var ObjectiveTextPtr = game.ReadValue<IntPtr>(ObjectivesText + 0x28 * obj + 0x8);
            var ObjectiveTextPtr2 = game.ReadValue<IntPtr>(ObjectiveTextPtr + 0x28);
            var ObjectiveText = game.ReadString(ObjectiveTextPtr2, 300);
            // var ObjectiveText = new DeepPointer(ObjectivesText + 0x28 * obj + 0x8, 0x28).DerefString(game, ReadStringType.UTF8, 128);
            vars.Log("OBJECTIVE " + ObjectiveEnum + ": " + ObjectiveText);
        }

        var Objective = game.ReadValue<int>(GameManagerReference + 0x450);
        vars.Log("------Objective: " + Objective);
        // SceneManager 458, IsLoading 380
        var IsLoading = new DeepPointer(GameManagerReference + 0x458, 0x380).Deref<bool>(game);
        vars.Log("------IsLoading: " + IsLoading);

        // var LoadingScreenWidgetReference = game.ReadValue<IntPtr>(actorPtr + 0x2A0);
        // var UIReference = game.ReadValue<IntPtr>(actorPtr + 0x2B0);
        // vars.Log("--LoadingScreenWidgetReference: " + LoadingScreenWidgetReference.ToString("X"));
        // vars.Log("--UIReference: " + UIReference.ToString("X")); 
        // var UIReferenceName = vars.ReadFNameOfObject(UIReference);
        // vars.Log("----Name: " + UIReferenceName);
        // var UIReferenceVisibility = game.ReadValue<byte>(UIReference + 0xC3);
        // vars.Log("----Visibility: " + UIReferenceVisibility);

        // var UIReferenceNUMBER = game.ReadValue<int>(UIReference + 0x180);
        // vars.Log("----ActiveSequencePlayers.Count: " + UIReferenceNUMBER);

        // var LoadingBar = game.ReadValue<IntPtr>(UIReference + 0x280);
        // vars.Log("----LoadingBar: " + LoadingBar.ToString("X"));
        // var LoadingBarName = vars.ReadFNameOfObject(LoadingBar);
        // vars.Log("------Name: " + LoadingBarName);

        // var Percent = game.ReadValue<float>(LoadingBar + 0x2C8);
        // vars.Log("------Percent: " + Percent);
    }
}