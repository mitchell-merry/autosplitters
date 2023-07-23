state("the ball pit") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "The Ball Pit";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
    vars.ReadSceneName = (Func<IntPtr, string>)(scene => {
        return vars.Helper.ReadString(256, ReadStringType.UTF8, scene + 0x38);
    });

	current.activeScene = current.loadingScene = "";
}

onStart
{
	// vars.Log(current.activeScene);
	// vars.Log(current.loadingScene);

    vars.Log(vars.Helper.Scenes.Active.Address.ToString("X"));
}

update
{
	current.activeScene = vars.ReadSceneName(vars.Helper.Scenes.Active.Address);
	current.loadingScene = vars.ReadSceneName(vars.Helper.Scenes.Loaded[0].Address);

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");
}

start
{
	return old.activeScene == "Menu" && current.activeScene == "McDongs";
}

split
{
	// return !old.gameEnd && current.gameEnd;
}

isLoading
{
    return current.activeScene != current.loadingScene;
}