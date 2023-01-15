state("Poop Killer 5") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Poop Killer 5";
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
	current.nonLoadScene = (current.activeScene != "SceneLoader40") ? current.activeScene : current.nonLoadScene;
}

isLoading
{
	return current.loadingScene == "SceneLoader40"
	    || current.activeScene  == "SceneLoader40"
		|| current.loadingScene != current.activeScene;
}

start
{
	return old.nonLoadScene == "POOPNOVO5INTRO"
	    && current.nonLoadScene == "POOPNOVO5";
}