state("Reflector") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Reflector";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

    settings.Add("split", true, "Split on complete:");
    settings.Add("Level1RTM_Level2RTM", false, "Level 1", "split");
    settings.Add("Level2RTM_WinScene", true, "Level 2 (End)", "split");
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");
}

start
{
    return old.activeScene == "MainMenu" && current.activeScene == "Level1RTM";
}

split
{
    if (old.loadingScene != current.loadingScene)
    {
        var key = old.loadingScene + "_" + current.loadingScene;
        vars.Log(key);
        if (settings.ContainsKey(key) && settings[key])
        {
            return true;
        }
    }
}

isLoading
{
    return current.loadingScene != current.activeScene;
}