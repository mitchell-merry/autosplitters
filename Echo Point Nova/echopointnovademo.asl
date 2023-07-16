state("Greylock-Win64-Shipping")
{
    // cheat table in repo describes these paths
    long FNamePool: 0x54809D0;

    long worldFName: 0x56A6B60, 0x18;

    // World -> GameState -> CurrentActiveZone
    long ActiveZone: 0x56A6B60, 0x120, 0x410;
    long zoneFName: 0x56A6B60, 0x120, 0x410, 0x18;
    // World -> GameState -> CurrentActiveZone -> SpawnCount
    int SpawnCount: 0x56A6B60, 0x120, 0x410, 0x510;       // total number of guys that spawn
    // World -> GameState -> CurrentActiveZone -> BattleCountForUI
    int BattleCountForUI: 0x56A6B60, 0x120, 0x410, 0x518; // number left

    // World -> AuthorityGameMode -> PlayerControllers -> [0] -> Character -> CapsuleComponent -> ComponentVelocity (Vector)
    float VelocityX: 0x56A6B60, 0x118, 0x3C8, 0x0, 0x260, 0x290, 0x140;
    float VelocityZ: 0x56A6B60, 0x118, 0x3C8, 0x0, 0x260, 0x290, 0x144;
    float VelocityY: 0x56A6B60, 0x118, 0x3C8, 0x0, 0x260, 0x290, 0x148;
}

startup
{
	vars.Log = (Action<object>)(output => print("[Echo Point Nova] " + output));
    settings.Add("split_zone", true, "Split on orb event");
    settings.Add("split_Zone_enter", false, "Enter Wind Temple", "split_zone");
    settings.Add("split_Zone", false, "Beat Wind Temple", "split_zone");
    settings.Add("split_ICICLES_enter", false, "Enter Ice Castle", "split_zone");
    settings.Add("split_ICICLES", false, "Beat Ice Castle", "split_zone");
    settings.Add("split_SENTRY_enter", false, "Enter Fire Temple", "split_zone");
    settings.Add("split_SENTRY", false, "Beat Fire Temple", "split_zone");
    settings.Add("split_desert_enter", false, "Enter Final Fight", "split_zone");
    settings.Add("split_desert", true, "Beat Final Fight", "split_zone");

    settings.Add("start_zone_enter", false, "Start time on entering a fight");
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

    current.hasMovedInWorld = false;
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

    
    if (current.world == "MainMenu") current.hasMovedInWorld = false;

    if ((old.VelocityX == 0 && current.VelocityX != 0)
     || (old.VelocityY == 0 && current.VelocityY != 0)
     || (old.VelocityZ == 0 && current.VelocityZ != 0))
    {
        current.hasMovedInWorld = true;
    }
}

start
{
    if (settings["start_zone_enter"] &&
        old.zone != current.zone &&
        old.zone == "None"
    ) {
        return true;
    }

    return !old.hasMovedInWorld && current.hasMovedInWorld;
}

onStart
{
    vars.CompletedSplits = new Dictionary<string, bool>();
}

split
{
    // start an orb fight
    if (old.zone != current.zone &&
        old.zone == "None" &&
        vars.CheckSplit("split_" + current.zone + "_enter")
    ) {
        return true;
    }

    // beat fight
    if (old.BattleCountForUI > current.BattleCountForUI &&
        current.BattleCountForUI <= 0 &&
        vars.CheckSplit("split_" + old.zone)
    ) {
        return true;
    }
}

reset
{
    return old.world == "None" && current.world == "MainMenu";
}