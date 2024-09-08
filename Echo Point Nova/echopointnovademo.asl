state("Greylock-Win64-Shipping") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Echo Point Nova";
    vars.Helper.Settings.CreateFromXml("Components/EchoPointNova.Settings.xml");
}

init
{
    vars.GWorld = vars.Helper.ScanRel(0x3, "48 8B 05 ?? ?? ?? ?? 48 3B C? 48 0F 44 C? 48 89 05 ?? ?? ?? ?? E8");
    IntPtr NamePoolData = vars.Helper.ScanRel(0xD, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15");
    vars.Log("Found GWorld: 0x" + vars.GWorld.ToString("X"));
    vars.Log("Found NamePoolData: 0x" + NamePoolData.ToString("X"));
    
    // The following code derefences FName structs to their string counterparts by
    // indexing this FNamePool table

    // `fname` is the actual struct, not a pointer to the struct
    vars.CachedFNames = new Dictionary<long, string>();
    vars.ReadFName = (Func<long, string>)(fname => 
    {
        if (vars.CachedFNames.ContainsKey(fname)) return vars.CachedFNames[fname];

        int name_offset  = (int) fname & 0xFFFF;
        int chunk_offset = (int) (fname >> 0x10) & 0xFFFF;

        var base_ptr = new DeepPointer((IntPtr) NamePoolData + 0x10 + chunk_offset * 0x8, name_offset * 0x2);
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
    // GWorld -> Name
    current.worldFName = vars.Helper.Read<long>(vars.GWorld, 0x18);

    // GWorld -> GameState -> CurrentActiveZone -> Name
    current.zoneFName = vars.Helper.Read<long>(vars.GWorld, 0x120, 0x420, 0x18);
    // GWorld -> GameState -> CurrentActiveZone -> SpawnCount
    current.SpawnCount = vars.Helper.Read<int>(vars.GWorld, 0x120, 0x420, 0x660);       // total number of guys that spawn
    // GWorld -> GameState -> CurrentActiveZone -> BattleCountForUI
    current.BattleCountForUI = vars.Helper.Read<int>(vars.GWorld, 0x120, 0x420, 0x668); // number left

    // GWorld -> AuthorityGameMode -> PlayerControllers -> [0] -> Character -> CapsuleComponent -> ComponentVelocity (Vector)
    current.VelocityX = vars.Helper.Read<float>(vars.GWorld, 0x118, 0x488, 0x0, 0x260, 0x290, 0x140);
    current.VelocityY = vars.Helper.Read<float>(vars.GWorld, 0x118, 0x488, 0x0, 0x260, 0x290, 0x144);
    current.VelocityZ = vars.Helper.Read<float>(vars.GWorld, 0x118, 0x488, 0x0, 0x260, 0x290, 0x148);

    // Deref useful FNames here
    IDictionary<string, object> olddict = old;
    IDictionary<string, object> currdict = current;
    var dontlogthese = new List<string>() { "VelocityX", "VelocityY", "VelocityZ" };
    foreach (var fname in new List<string>(currdict.Keys))
    {
        if (!fname.EndsWith("FName")) {
            if (!olddict.ContainsKey(fname)) {
                vars.Log(fname + ": " + currdict[fname].ToString());
                continue;
            }

            if (dontlogthese.Contains(fname)) {
                continue;
            }
            
            if(olddict[fname].ToString() != currdict[fname].ToString()) {
                vars.Log(fname + ": " + olddict[fname].ToString() + " -> " + currdict[fname].ToString());
            }
            continue;
        }
        
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