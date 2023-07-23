state("Lust From Beyond - Scarlet") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Lust From Beyond - Scarlet";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();
	vars.Helper.Settings.CreateFromXml("Components/LFBScarlet.Settings.xml");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        return true;
    });

    vars.ReadSceneName = (Func<IntPtr, string>)(scene => {
        // asl-help has this offset at 0x10. I don't know why it's 0x18 for this game, but it is.
        string path = vars.Helper.ReadString(256, ReadStringType.UTF8, scene + 0x18, 0x0);
        string name = System.IO.Path.GetFileNameWithoutExtension(path);
        return name == "" ? null : name;
    });

    vars.CompletedSplits = new List<string>();
    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || vars.CompletedSplits.Contains(key)
        ) {
            return false;
        }

        vars.CompletedSplits.Add(key);
        vars.Log("Completed: " + key);
        return true;
    });
}

onStart
{
    timer.IsGameTimePaused = current.isLoading ?? false;

    vars.Log(current.activeScene);
    vars.Log(current.loadingScene);
}

update
{
    current.activeScene = vars.ReadSceneName(vars.Helper.Scenes.Active.Address) ?? current.activeScene;
    current.loadingScene = vars.ReadSceneName(vars.Helper.Scenes.Loaded[0].Address) ?? current.loadingScene;

    if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
    if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

    current.isLoading = current.activeScene == "SC_Loading" || current.loadingScene == "SC_Loading"
                     || current.activeScene == "SC_Loading_BlackScreen" || current.loadingScene == "SC_Loading_BlackScreen";
}

start
{
    return old.activeScene == "SC_Loading" && current.activeScene == "SC_Theatre_Prologue";
}

split
{
    return old.activeScene != current.activeScene
        && (old.activeScene == "SC_Loading" || old.activeScene == "SC_Loading_BlackScreen")
        && vars.CheckSplit("scene_" + current.activeScene);
}

isLoading
{
    return current.isLoading;
}