// unreal 4-4.22

state("")
{
    // to find this https://www.youtube.com/watch?v=UzjhJTaYFn4 or some dumper
    long GNames: ;

    int worldFName: , 0x18;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "TEMPLATE";
    // vars.Helper.Settings.CreateFromXml("Components/TEMPLATE.Settings.xml");
    
    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });
    
    vars.CompletedSplits = new HashSet<string>();

    // vars.Helper.AlertLoadless();
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

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
}