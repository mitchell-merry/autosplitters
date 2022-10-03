state("Bloodwash") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
    vars.MainMenu = "MainMenuWasher";
    vars.LoadingScreen = "LoadingScreenScene";
    vars.Intro = "IntroScenev2";
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;
}

start 
{
    return current.activeScene == vars.Intro && old.activeScene == vars.LoadingScreen;    
}

isLoading 
{
    return current.activeScene != current.loadingScene
        || current.activeScene == vars.LoadingScreen
        || current.loadingScene == vars.LoadingScreen;
}

reset 
{
    return current.activeScene != current.loadingScene
        && current.loadingScene == vars.MainMenu
        && current.activeScene == vars.LoadingScreen;
}