state("Turbo Overkill") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Turbo Overkill";
    vars.Helper.LoadSceneManager = true;
    // vars.Helper.Settings.CreateFromXml("Components/TEMPLATE.Settings.xml");

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        // == doesn't be workin'
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });

    vars.CompletedSplits = new HashSet<string>();
    
    // vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var LevelInstance = mono["LevelInstance"];
        vars.Helper["igt"] = LevelInstance.Make<int>("main", "secondsPlayed");
        vars.Helper["episode"] = LevelInstance.Make<int>("main", "levelEpisodeIndex");
        vars.Helper["level"] = LevelInstance.Make<int>("main", "levelData_level");
        vars.Helper["isComplete"] = LevelInstance.Make<bool>("main", "levelIsComplete");

        var LoadingScreenManager = mono["LoadingScreenManager"];
        vars.Helper["isLoading"] = LoadingScreenManager.Make<bool>("main", "isLoading");
        
        return true;
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

    vars.First = true;
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    IDictionary<string, object> currentLookup = current;
    foreach (var key in new List<string>(currentLookup.Keys))
    {
        if (vars.First) {
            object value = currentLookup[key];
            vars.Log(key + ": " + value);
        }
        else
        {
            vars.Watch(old, current, key);
        }
    }

    vars.First = false;
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log(current.activeScene);
}