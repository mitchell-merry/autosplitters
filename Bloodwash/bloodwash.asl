state("Bloodwash")
{
    string128 loadingScene: "UnityPlayer.dll", 0x168FF58, 0x28, 0x0, 0x10, 0xE;
    string128 activeScene: "UnityPlayer.dll", 0x168FF58, 0x50, 0x0, 0x10, 0xE;
}

init
{
    vars.MainMenu = "MainMenuWasher.unity";
    vars.LoadingScreen = "LoadingScreenScene.unity";
    vars.Intro = "IntroScenev2.unity";
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