state("Haunted Gas Station") { }

startup
{
	var bytes = File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin");
	var type = Assembly.Load(bytes).GetType("ASLHelper.Unity");
	vars.Helper = Activator.CreateInstance(type, timer, this);
	vars.Helper.LoadSceneManager = true;
	
	vars.Log = (Action<object>)(output => print("[HGS] " + output));
}

init
{
	vars.Helper.Load();
}

update
{
	if (!vars.Helper.Update())
		return false;

	current.activeScene = vars.Helper.Scenes.Active.Index;

	if (current.activeScene == -1 || vars.Helper.Scenes.Loading.Count != 1)
	{
		vars.Log(current.activeScene + ", " + vars.Helper.Scenes.Loading.Count);
		return false;
	}

	current.loadingScene = vars.Helper.Scenes.Loading[0].Index;

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

exit
{
	vars.Helper.Dispose();
}

shutdown
{
	vars.Helper.Dispose();
}