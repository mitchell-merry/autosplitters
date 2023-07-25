state("The Pale Man") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "The Pale Man";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    vars.MainScenes = new List<string>() { "Level 1" , "Medium", "Hard", "Nightmare" };
    vars.EndScenes = new List<string>() { "Ending 1", "Ending 2" };
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;


    if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
    if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");
}

start
{
    return old.activeScene == "MainMenu" && vars.MainScenes.Contains(current.activeScene);
}

split
{
    return vars.MainScenes.Contains(old.loadingScene) && vars.EndScenes.Contains(current.loadingScene);
}