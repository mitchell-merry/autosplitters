state("Returnal-Win64-Shipping")
{
    long FNamePool: 0x23560;

    long cinematicFName: "Returnal-Engine-Win64-Shipping.dll", 0x15204F8, 0x198, 0x38, 0x0, 0x30, 0x7A0, 0x1C8, 0x18;

    long worldFName: "Returnal-Engine-Win64-Shipping.dll", 0x15204F8, 0x140, 0x7A8, 0x10, 0x18;
    // string16 text: "Returnal-Engine-Win64-Shipping.dll", 0x15204F8, 0x198, 0x38, 0x0, 0x30, 0x390, 0x490, 0x948, 0x720, 0x128, 0x28, 0x0;
    // long text: "Returnal-Engine-Win64-Shipping.dll", 0x15204F8, 0x198, 0x38, 0x0, 0x30, 0x390, 0x490, 0x948, 0x720, 0x128;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Returnal";
    // vars.Helper.Settings.CreateFromXml("Components/TEMPLATE.Settings.xml");
    
    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (oldValue != currentValue)
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });
    
    vars.CompletedSplits = new HashSet<string>();
    
    // vars.Helper.AlertLoadless();
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

    // vars.Log(current.text);
}

update
{
    // if (old.text != current.text) vars.Log(current.text);

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
        // if (newName == "None" && newKeyExists)
        //     continue;
        
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
}

start
{
    return old.cinematic == "BP_Cinematic_AFStart04" && current.cinematic == "None";
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
}