state("Happy's Humble Burger Farm") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "HHBF";
	vars.Helper.StartFileLogger("HHBF.log");
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		// var ems = mono["employeeManualScript"];
		// vars.Helper["manualUsable"] = mono.Make<bool>(ems, "instance", "usable");

		var pm = mono["progressManager"];
		vars.Helper["day"] = mono.Make<int>(pm, "instance", "currentDay");
		vars.Helper["lastScene"] = mono.MakeString(pm, "instance", "lastScene");
		vars.Helper["currentScene"] = mono.MakeString(pm, "instance", "currentScene");

		return true;
	});
}

onStart
{
	vars.Log(current.day);
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	if(current.activeScene != old.activeScene) vars.Log("SceneManager.activeScene: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("SceneManager.loadingScene: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

	// if(current.manualUsable != old.manualUsable) vars.Log("manualUsable " + current.manualUsable);
	if(current.day != old.day) vars.Log("day " + current.day);
	if(current.lastScene != old.lastScene) vars.Log("progressManager.lastScene " + current.lastScene);
	if(current.currentScene != old.currentScene) vars.Log("progressManager.currentScene " + current.currentScene);
}

start
{
	// Starting on loading into Apartment
	return old.activeScene != current.activeScene
		&& old.activeScene == "Main Menu"
		&& current.activeScene == "Apartment";

	// Start on putting the manual away
	// return old.manualUsable && !current.manualUsable
	// 	&& current.activeScene == "Apartment";
}

isLoading
{
	return current.lastScene == current.currentScene
		|| current.loadingScene != current.activeScene;
}