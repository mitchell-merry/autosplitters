state("Christmas Massacre") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();
    // vars.Helper.Settings.CreateFromXml("Components/ChristmasMassacre.Settings.xml");
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

    if(current.activeScene != old.activeScene) vars.Log("a: " + old.activeScene + ", " + current.activeScene);
    if(current.loadingScene != old.loadingScene) vars.Log("l: " + old.loadingScene + ", " + current.loadingScene);
}


start
{
    return current.activeScene != "02 Catholic Scene" && old.activeScene == "01 Intro Cutscene";
}

split
{
    return current.activeScene == "32 Asylum Escape" && current.loadingScene == "00 Main Menu with Level select" && old.loadingScene != current.loadingScene;
    // return current.loadingScene != old.loadingScene
        // && settings.ContainsKey(old.loadingScene)
        // && settings[old.loadingScene];
}

isLoading
{
    return current.activeScene != current.loadingScene;
}