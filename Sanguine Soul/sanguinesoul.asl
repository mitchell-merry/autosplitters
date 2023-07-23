// unreal 4.23+

state("SanguineSoul-Win64-Shipping")
{
    // doesn't seem to work
    // bool IfLoading: 0x3018048, 0x140, 0x38, 0x0, 0x30, 0x358, 0x8BA;
    
    long GNames: 0x2EC0B48;
    long worldFName: 0x3018048, 0x18;
}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.GameName = "Sanguine Soul";
	vars.Helper.AlertLoadless();
    vars.Helper.Settings.CreateFromXml("Components/SanguineSoul.Settings.xml");
}

init
{
    // `fname` is the index into the GNames array
    vars.CachedFNames = new Dictionary<long, string>();
    vars.ReadFName = (Func<long, string>)(fname => 
    {
        if (vars.CachedFNames.ContainsKey(fname)) return vars.CachedFNames[fname];

        int chunk_index  = (int) fname / 0x4000;
        int element_index = (int) fname % 0x4000;

        var name = vars.Helper.ReadString(256, ReadStringType.UTF8, (IntPtr) current.GNames + chunk_index * 0x8, element_index * 0x8, 0x10);
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

start
{
    return old.world == "MainMenuLevel" && current.world == "Level1_Cutscene";
}

split
{
    return old.world != current.world && vars.CheckSplit("level__" + old.world + "__" + current.world);
}

// isLoading
// {
//     return current.IfLoading;
// }