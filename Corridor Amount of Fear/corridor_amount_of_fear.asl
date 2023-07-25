// The typo is the game's, not mine
state("Corridor Amound of Fear") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "C:AOF";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    settings.Add("split_scene", true, "Split on completing scene:");
    settings.Add("Street", false, "Street", "split_scene");
    settings.Add("Act 1", false, "Act 1", "split_scene");
    settings.Add("Act 2", false, "Act 2", "split_scene");
    settings.Add("Act 3", false, "Act 3", "split_scene");
    settings.Add("Act 4", true, "Act 4", "split_scene");
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

    // if(current.activeScene != old.activeScene) vars.Log("a: " + old.activeScene + ", " + current.activeScene);
    // if(current.loadingScene != old.loadingScene) vars.Log("l: " + old.loadingScene + ", " + current.loadingScene);
}

isLoading
{
    return current.loadingScene == "SceneLoader";
}

start
{
    return old.activeScene != current.activeScene && current.activeScene == "Street";
}

split
{
    return old.loadingScene != current.loadingScene
        && settings.ContainsKey(old.loadingScene)
        && settings[old.loadingScene];
}