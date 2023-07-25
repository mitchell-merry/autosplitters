state("DevilCatcherVer2.3") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    settings.Add("split_scene", true, "Split on completing scene:");
    settings.Add("Level1", false, "Level 1", "split_scene");
    settings.Add("DevilBoss", false, "Devil Boss", "split_scene");
    settings.Add("Level2", false, "Level 2", "split_scene");
    settings.Add("GodBoss", true, "God Boss", "split_scene");
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

    // if(current.activeScene != old.activeScene) vars.Log("a: " + old.activeScene + ", " + current.activeScene);
    // if(current.loadingScene != old.loadingScene) vars.Log("l: " + old.loadingScene + ", " + current.loadingScene);
}

start
{
    return old.activeScene == "MainMenu" && current.activeScene == "Level1";
}

split
{
    return old.loadingScene != current.loadingScene && settings[current.loadingScene];
}

isLoading
{
    return current.loadingScene != current.activeScene;
}

reset
{
    return old.loadingScene != current.loadingScene && current.loadingScene == "MainMenu";
}