state("") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "";
    vars.Helper.LoadSceneManager = true;
    // vars.Helper.Settings.CreateFromXml("Components/TEMPLATE.Settings.xml");

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (oldValue != currentValue)
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });

    vars.CompletedSplits = new HashSet<string>();
    
    // vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
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
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    vars.Watch(old, current, "activeScene");
    vars.Watch(old, current, "loadingScene");
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log(current.activeScene);
}