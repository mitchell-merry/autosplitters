state("Haunted Gas Station") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "HGS";
	vars.Helper.LoadSceneManager = true;
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Index;

	if (current.activeScene == -1 || vars.Helper.Scenes.Loaded.Count != 1)
	{
		vars.Log(current.activeScene + ", " + vars.Helper.Scenes.Loaded.Count);
		return false;
	}

	current.loadingScene = vars.Helper.Scenes.Loaded[0].Index;

	if (old.loadingScene != current.loadingScene)
		vars.Log("loadingScene: " + old.loadingScene + " -> " + current.loadingScene);

	if (old.activeScene != current.activeScene)
		vars.Log("activeScene: " + old.activeScene + " -> " + current.activeScene);
}

start
{
	return current.loadingScene == 2 && current.activeScene == 2
	   && (old.activeScene == 0 || old.activeScene == 1);
}

split
{
	return current.activeScene == 2 && old.loadingScene == 2 && current.loadingScene == 4;
}
