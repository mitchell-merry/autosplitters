state("Cannibal Abduction") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Cannibal Abduction";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	current.activeScene = current.loadingScene = current.nonLoadScene = "";
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;
	// current.nonLoadScene = (current.activeScene != "SceneLoader40") ? current.activeScene : current.nonLoadScene;

	if (current.loadingScene != old.loadingScene)
		vars.Log("loadingScene: " + old.loadingScene + " -> " + current.loadingScene);

	if (current.activeScene != old.activeScene)
		vars.Log("activeScene: " + old.activeScene + " -> " + current.activeScene);
}

isLoading
{
	return current.activeScene != current.loadingScene;
}

start
{
	return old.activeScene == "Scn_MainMenu"
	    && current.activeScene == "Scn_Mov_Intro";
}