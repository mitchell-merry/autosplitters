state("Bread&Fred") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Bread & Fred";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertGameTime();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // vars.Helper["timer"] = mono.Make<long>("Timer", 1, "Instance", "_currentRunTimer", "elapsed");
        vars.Helper["state"] = mono.Make<long>("GameManager", 2, "Instance", "_currentState");
        return true;
    });
}

onStart
{
    vars.Log(current.activeScene);
    vars.Log(current.timer);
}

update
{
    vars.Watch("state");
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
    if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");
}