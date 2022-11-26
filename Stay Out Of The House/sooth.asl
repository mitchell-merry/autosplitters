state("Stay out of the House") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "SOOTH";
	vars.Helper.LoadSceneManager = true;
	// vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var sm = mono["SavingManager"];
		vars.Helper["playTime"] = mono.Make<double>(sm, "playTime");
		return true;
	});
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");
	if(current.playTime != old.playTime) vars.Log("pt: " + old.playTime + ", " + current.playTime);
}

onStart
{
	vars.Log("a: \"" + current.activeScene + "\"");
	vars.Log("l: \"" + current.loadingScene + "\"");
	vars.Log("playTime: " + current.playTime);
}