state("Walls Closing In HDRP") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    vars.Scenes = new[] { "New Prologue", "The Farmhouse", "Interrogation", "The Hood", "End Credits" };

    settings.Add("split_scene", true, "Split on completing scene:");
    settings.Add("Kidnap Flashback", false, "Kidnap Flashback", "split_scene");
    settings.Add("New Prologue", false, "Basement", "split_scene");
    settings.Add("The Farmhouse", false, "Farmhouse", "split_scene");
    settings.Add("The Hood", true, "The Hood", "split_scene");
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;
}

start
{
    return old.activeScene == "Main Menu"
        && current.activeScene == "Kidnap Flashback";
}

reset
{
    return old.loadingScene != current.loadingScene
        && current.loadingScene == "Main Menu";
}

split
{
    return old.loadingScene != current.loadingScene
        && settings.ContainsKey(old.loadingScene)
        && settings[old.loadingScene];
}

isLoading 
{
    return current.activeScene != current.loadingScene;
}