state("TEMPLATE") {}

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

    vars.Watchers = null;

    vars.yourSigResult = vars.Helper.ScanRel(0x1, "00 ??");

    vars.Watchers = new MemoryWatcherList() {
        new MemoryWatcher<int>(
            new DeepPointer(
                vars.yourSigResult,
                0x8,
            )
        ) { name = "yourField" },
    };
}

update
{
    IDictionary<string, object> currdict = current;
    
    // read the values, place them all in current
    vars.Watchers.UpdateAll(game);
    foreach (var watcher in vars.Watchers)
    {
        currdict[watcher.Name] = watcher.Current;
    }
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
}