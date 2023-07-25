state("JANITOR BLEEDS") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Janitor Bleeds";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["state"] = mono.Make<int>("MenuManager", "instance", "currentGameState");
        return true;
    });
}

isLoading
{
    return current.loadingScene != current.activeScene
        || current.state == 0
        || current.state == 2;
}