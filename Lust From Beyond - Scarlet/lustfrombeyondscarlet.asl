state("Lust From Beyond - Scarlet") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Lust From Beyond - Scarlet";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		return true;
	});

    vars.ReadSceneName = (Func<IntPtr, string>)(scene => {
        // asl-help has this offset at 0x10. I don't know why it's 0x18 for this game, but it is.
        string path = vars.Helper.ReadString(256, ReadStringType.UTF8, scene + 0x18, 0x0);
        string name = System.IO.Path.GetFileNameWithoutExtension(path);
        return name == "" ? null : name;
    });
}

onStart
{
    timer.IsGameTimePaused = current.isLoading ?? false;

	vars.Log(current.activeScene);
	vars.Log(current.loadingScene);
}

update
{
	current.activeScene = vars.ReadSceneName(vars.Helper.Scenes.Active.Address) ?? current.activeScene;
    current.loadingScene = vars.ReadSceneName(vars.Helper.Scenes.Loaded[0].Address) ?? current.loadingScene;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

    current.isLoading = current.activeScene == "SC_Loading" || current.loadingScene == "SC_Loading";
}

start
{
    return old.activeScene == "SC_Loading" && current.activeScene == "SC_Theatre_Prologue";
}

split
{
    // TODO implement
    // return old.activeScene == "SC_Theatre_Prologue" && current.activeScene == "SC_Loading";
}

isLoading
{
    return current.isLoading;
}