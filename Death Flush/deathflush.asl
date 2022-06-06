state("Death Flush")
{
    string128 loadingScene: "UnityPlayer.dll", 0x19423F8, 0x28, 0x0, 0x10, 0x7;
    string128 activeScene: "UnityPlayer.dll", 0x19423F8, 0x50, 0x0, 0x10, 0x7;
}

init
{
    /*
        "INSTRUCTIONS", "attendant", "ENDING", "Boss Scene", "start scene", "LOADING", "main menu"
    */
    vars.MainMenu = "main menu.unity";
    vars.Instructions = "INSTRUCTIONS.unity";
    vars.Loading = "LOADING.unity";
    vars.Start = "start scene.unity";
}

start 
{
    return old.loadingScene == vars.MainMenu && current.loadingScene == vars.Instructions;    
}

split
{
    if(current.loadingScene == null || current.activeScene == null) return false;

    return current.loadingScene != old.loadingScene
        && old.loadingScene != vars.Loading
        && old.loadingScene != vars.Instructions;
}

isLoading 
{
    return current.activeScene != current.loadingScene
        || current.activeScene == vars.Loading
        || current.loadingScene == vars.Loading;
}

