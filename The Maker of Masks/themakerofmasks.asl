state("The Maker of Masks") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "The Maker of Masks";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var mm = "MenuManager";
		vars.Helper["inStart"] = mono.Make<bool>(mm, "instance", "isInStartMenu");
		vars.Helper["inPause"] = mono.Make<bool>(mm, "instance", "isInPauseMenu");
		vars.Helper["inOptions"] = mono.Make<bool>(mm, "instance", "isInOptionsMenu");

		return true;
	});
}

onStart
{
	vars.Log(current.activeScene);
	vars.Log(current.inStart);
	vars.Log(current.inPause);
	vars.Log(current.inOptions);
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

	vars.Watch("inStart");
	vars.Watch("inPause");
	vars.Watch("inOptions");
}

start
{
	return old.inStart && !current.inStart;
}

isLoading
{
	return current.activeScene != current.loadingScene;
}