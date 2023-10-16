state("DingDongDead") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Ding Dong Dead";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.Settings.CreateFromXml("Components/DingDongDead.Settings.xml");

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });

    vars.EndingScenes = new HashSet<string>() { "NewsRoom", "TextEndingAttackedPleasant", "TextEndingSavedRex" };

    vars.CompletedSplits = new HashSet<string>();
    
    vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["items"] = mono.MakeList<IntPtr>("KickStarter", "runtimeInventoryComponent", "playerInvCollection", "invInstances");

        var InvInstance = mono["InvInstance"];
        vars.GetInvInstanceId = (Func<IntPtr, int>)(item =>
        {
            return vars.Helper.Read<int>(item + InvInstance["itemID"]);
        });

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

start
{
    return old.activeScene == "MainMenu" && current.activeScene == "House";
}

split
{
    if (settings["item"]) {
        foreach (var itemPtr in current.items) {
            var itemId = vars.GetInvInstanceId(itemPtr);
            if (vars.CheckSplit("item_" + itemId)) {
                return true;
            }
        }
    }

    return old.loadingScene != current.loadingScene && vars.EndingScenes.Contains(current.loadingScene);
}

isLoading
{
    return current.loadingScene != current.activeScene;
}