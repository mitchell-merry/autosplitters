state("Bendy and the Dark Revival") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Bendy and the Dark Revival";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gm = mono["GameManager"];
		vars.Helper["GameState"] = mono.Make<int>(gm, "m_Instance", "GameState");
		vars.Helper["IsLoading"] = mono.Make<bool>(gm, "m_AsyncLoader", "m_IsLoading");

		return true;
	});
}

onStart
{
	vars.Log(current.GameState);
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ?? current.loadingScene;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

	vars.Watch("GameState");
	vars.Watch("IsLoading");
}