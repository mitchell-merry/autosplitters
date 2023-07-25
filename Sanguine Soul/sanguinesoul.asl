state("SanguineSoul-Win64-Shipping")
{
    // doesn't seem to work
    // bool IfLoading: 0x3018048, 0x140, 0x38, 0x0, 0x30, 0x358, 0x8BA;
    
    long GNames: 0x2EC0B48;
    int worldFName: 0x3018048, 0x18;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Sanguine Soul";
    vars.Helper.Settings.CreateFromXml("Components/SanguineSoul.Settings.xml");

    vars.CompletedSplits = new HashSet<string>();

    vars.Helper.AlertRealTime();
}

init
{
    // `fname` is the index into the GNames array
    var cachedFNames = new Dictionary<int, string>();
    vars.ReadFName = (Func<int, string>)(fname => 
    {
        string name;
        if (cachedFNames.TryGetValue(fname, out name))
            return name;

        int chunk_index  = (int) fname / 0x4000;
        int element_index = (int) fname % 0x4000;

        name = vars.Helper.ReadString(256, ReadStringType.UTF8, (IntPtr) current.GNames + chunk_index * 0x8, element_index * 0x8, 0x10);
        cachedFNames[fname] = name;

        return name;
    });

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key => {
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
}

update
{
    // Deref useful FNames here
    IDictionary<string, object> currentLookup = current;
    foreach (var key in new List<string>(currentLookup.Keys))
    {
        object value = currentLookup[key];

        if (!key.EndsWith("FName") || value.GetType() != typeof(int))
            continue;
        
        // e.g. missionFName -> mission
        string newKey = key.Substring(0, key.Length - 5);
        string newName = vars.ReadFName((int) value);

        object oldName;
        bool newKeyExists = currentLookup.TryGetValue(newKey, out oldName);
        if (newName == "None" && newKeyExists)
            continue;
        
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

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
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
