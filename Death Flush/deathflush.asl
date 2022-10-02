state("Death Flush") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	settings.Add("split_scene", true, "Split on completing scene:");
	settings.Add("start scene", false, "Main Area", "split_scene");
	settings.Add("Boss Scene", true, "Boss", "split_scene");
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	if(current.activeScene != old.activeScene) vars.Log("a: " + old.activeScene + ", " + current.activeScene);
	if(current.loadingScene != old.loadingScene) vars.Log("l: " + old.loadingScene + ", " + current.loadingScene);
}


start
{
	return old.activeScene != "main menu" && current.activeScene == "INSTRUCTIONS";
}

split
{
	return current.loadingScene != old.loadingScene
	    && settings.ContainsKey(old.loadingScene)
	    && settings[old.loadingScene];
}

isLoading
{
    return current.activeScene != current.loadingScene
        || current.activeScene == "LOADING"
        || current.loadingScene == "LOADING";
}