state("Sniper Killer Demo") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Sniper Killer Demo";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

    settings.Add("split", true, "Split on completing level");
    settings.Add("split_SK_Prologue_1", false, "Pamela", "split");
    settings.Add("split_SK_Prologue_2", false, "Funside Carnival", "split");
    settings.Add("split_SK_Prologue_3", false, "Funside Carnival (Investigation)", "split");
    settings.Add("split_SK_Credits", true, "Gail (End)", "split");
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
    return old.activeScene == "SK_LoadingScreenScene" && current.activeScene == "SK_Prologue_0_5";
}

split
{
    if (old.loadingScene != current.loadingScene)
    {
        var key = "split_" + current.loadingScene;
        return settings.ContainsKey(key) && settings[key];
    }
}

isLoading
{
    return current.loadingScene != current.activeScene || current.activeScene == "SK_LoadingScreenScene";
}