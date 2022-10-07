state("Don't Be Afraid") {}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "DBA";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	settings.Add("start_after_cutscene", false, "Start after the first cutscene.");
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;
	
	if(current.activeScene != old.activeScene) vars.Log("a: " + old.activeScene + ", " + current.activeScene);
	if(current.loadingScene != old.loadingScene) vars.Log("l: " + old.loadingScene + ", " + current.loadingScene);
}

isLoading
{
	return current.activeScene != current.loadingScene;
}

start
{
	return (!settings["start_after_cutscene"]
	    && old.activeScene == "MainMenu ENG"
	    && current.activeScene == "Cutscene1Basement")
		|| (settings["start_after_cutscene"]
	    && old.activeScene == "Cutscene1Basement"
	    && current.activeScene == "Basement");
}