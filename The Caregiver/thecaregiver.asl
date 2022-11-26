state("TheCaregiver") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "The Caregiver";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var sgh = mono.GetClass("SaveGameHandler", 1);
		vars.Helper["isFading"] = mono.Make<bool>(sgh, "instance", "fadeControl", "isFading");

		return true;
	});
}

onStart
{
	vars.Log(current.loadingScene);
	vars.Log(current.activeScene);
	vars.Log(current.isFading);
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");
	vars.Watch("isFading");
}

start
{
	return old.activeScene == "CG_MainMenu" && current.activeScene == "CG_MainScene_New_2";
}

split
{
	return old.loadingScene == "CG_MainScene_New_2" && current.loadingScene == "Ending";
}