state("Clay_3-Win64-Shipping")
{
    long FNamePool: 0x6404EB0;
 
    long worldFName: 0x6684E78, 0x18;

    double x: 0x6684E78, 0x1B8, 0x38, 0x0, 0x30, 0x2E0, 0x328, 0x128;
    double z: 0x6684E78, 0x1B8, 0x38, 0x0, 0x30, 0x2E0, 0x328, 0x130;
    double y: 0x6684E78, 0x1B8, 0x38, 0x0, 0x30, 0x2E0, 0x328, 0x138;
}

startup
{
    double epsilon = 0.01;
    vars.Eq = (Func<double, double, bool>)((first, second) =>
    {
        return Math.Abs(first - second) < epsilon;
    });

    // as desired by the community /shrug
    vars.LoadingScreens = new List<string>() { "None", "Main_Menu", "Disclaimer" };

    vars.StartX = 32.55;
    vars.StartZ = 2586.16;
    vars.StartY = 111.48;
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
}

update
{
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
        
        // Debugging and such
        if (!newKeyExists)
        {
            print(newKey + ": " + newName);
        }
        else if (oldName != newName)
        {
            print(newKey + ": " + oldName + " -> " + newName);
        }

        currentLookup[newKey] = newName;
    }
}

start
{
    return (vars.Eq(old.x, vars.StartX) && vars.Eq(old.z, vars.StartZ) && vars.Eq(old.y, vars.StartY))
        && (!vars.Eq(old.x, current.x) || !vars.Eq(old.z, current.z) || !vars.Eq(old.y, current.y));
}

isLoading
{
    return vars.LoadingScreens.Contains(current.world);
}

exit
{
    timer.IsGameTimePaused = true;
}