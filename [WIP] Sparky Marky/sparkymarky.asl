// unreal 4.23+

state("OnlineHorror-Win64-Shipping")
{
    long FNamePool: 0x48F9918;
    long World: 0x4B1FF60;

    long worldFName: 0x4B1FF60, 0x18;
    long levelFName: 0x4B1FF60, 0x30, 0x20, 0x18;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Sparky Marky";
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

        try {

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
        } catch (Exception e) {
            vars.Log(e);
            vars.Log("Error Info:");
            vars.Log("  fname: " + fname.ToString("X"));
            vars.Log("  name_offset: " + name_offset.ToString("X"));
            vars.Log("  chunk_offset: " + chunk_offset.ToString("X"));
            vars.CachedFNames[fname] = "ERROR READING FNAME";
            return "ERROR READING FNAME";
        }
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
        
        // e.g. missionFName -> mission
        var key = fname.Substring(0, fname.Length-5);
        var val = vars.ReadFName((long)currdict[fname]);
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
}