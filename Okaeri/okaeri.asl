state("Okaeri") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Okaeri";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });

    var SceneLabels = new Dictionary<string, string>() {
        { "Exterior1", "Exterior" },
        { "Interior1", "Interior 1" },
        { "Interior2", "Interior 2" }
    };

    settings.Add("split_scene", true, "Split on completing scene:");
    foreach(var scene in SceneLabels.Keys)
    {
        settings.Add(scene, false, SceneLabels[scene], "split_scene");
    }
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;
}

isLoading
{
    return current.activeScene != current.loadingScene;
}

start
{
    return old.activeScene == "mainmenu"
        && current.activeScene == "Exterior1";
}

split
{
    return old.loadingScene != current.loadingScene
        && settings.ContainsKey(old.loadingScene) && settings[old.loadingScene];
}