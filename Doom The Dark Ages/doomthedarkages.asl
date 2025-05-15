state("DOOMTheDarkAges") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "DOOM: The Dark Ages";
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

    vars.idGameSystemLocal = vars.Helper.ScanRel(0x6, "FF 50 40 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0");
    vars.Log("Found idGameSystemLocal at 0x" + vars.idGameSystemLocal.ToString("X"));

    vars.Watchers = new MemoryWatcherList() {
        // enum GameState {
        //   GAME_STATE_MAIN_MENU = 0,
        //   GAME_STATE_LOADING = 1,
        //   GAME_STATE_INGAME = 2,
        // }
        new MemoryWatcher<int>(
            new DeepPointer(
                vars.idGameSystemLocal + 0x40
            )
        ) { Name = "gameState" }
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

isLoading
{
    return current.gameState == 1;
}