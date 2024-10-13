state("The Night of the Scissors") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "The Night of the Scissors";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();
}

init
{
    current.activeScene = current.loadingScene = "";
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    if (current.loadingScene != old.loadingScene)
        vars.Log("loadingScene: " + old.loadingScene + " -> " + current.loadingScene);

    if (current.activeScene != old.activeScene)
        vars.Log("activeScene: " + old.activeScene + " -> " + current.activeScene);
}

isLoading
{
    return current.activeScene != current.loadingScene;
}

start
{
    return old.activeScene == "IntroCutscene"
        && current.activeScene == "GameplayScene";
}