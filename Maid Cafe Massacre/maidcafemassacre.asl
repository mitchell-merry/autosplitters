state("MaidCafeMassacre") {}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Maid Cafe Massacre";
	vars.Helper.LoadSceneManager = true;

	vars.Helper.AlertLoadless();
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Index;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Index;
}

start
{
	return old.activeScene != current.activeScene && current.activeScene == 1;
}

split
{
	return old.loadingScene == current.loadingScene - 1
	    && old.loadingScene != 0;
}

isLoading
{
	return current.loadingScene != current.activeScene;
}