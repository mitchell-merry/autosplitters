state("the ball pit") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "The Ball Pit";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var m = "Menu";
		vars.Helper["inGame"] = mono.Make<bool>(m, "inGame");
		vars.Helper["gameEnd"] = mono.Make<bool>(m, "gameEnd");

		// var c = "Checkpoints";
		// vars.Helper["currCheckpoint"] = mono.Make<int>(c, "instance", "currentCheckpoint");
		return true;
	});

	current.activeScene = current.loadingScene = "";
}

onStart
{
	vars.Log(current.inGame);
	vars.Log(current.gameEnd);
	// vars.Log(current.currCheckpoint);
}

update
{
	// vars.Log(vars.Helper.Scenes.Active.Name);
	// vars.Log(vars.Helper.Scenes.Loaded);
	// foreach(var scene in vars.Helper.Scenes.Loaded)
	// {
	// 	vars.Log(scene.Name);
	// }
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

	// vars.Watch("currCheckpoint");
	vars.Watch("inGame");
	vars.Watch("gameEnd");
}

start
{
	return !old.inGame && current.inGame;
}

split
{
	return !old.gameEnd && current.gameEnd;
}