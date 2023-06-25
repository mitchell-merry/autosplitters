state("Dead From Beyond") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Dead From Beyond";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

    vars.Levels = new List<string>() { "Level1 Finalized", "Level 2", "Level 3 Withered" };
    
    settings.Add("round", true, "Split on reaching round");
    for (var i = 5; i <= 100; i += 5)
    {
        bool d = i == 100;
        settings.Add("round_" + i, d, "Round " + i, "round");
    }
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
        var GameDirector = mono["GameDirector"];
        vars.Helper["round"] = GameDirector.Make<int>("currentWave");
		return true;
	});
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
    return old.activeScene != current.activeScene &&
           old.activeScene == "Main Menu" &&
           vars.Levels.Contains(current.activeScene);
}

split
{
    return old.round != current.round &&
           settings.ContainsKey("round_" + current.round) &&
           settings["round_" + current.round];
}

isLoading
{
    return current.activeScene != current.loadingScene;
}