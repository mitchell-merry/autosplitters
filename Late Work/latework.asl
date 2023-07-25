state("Late Work") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Late Work";
    vars.Helper.LoadSceneManager = true;
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;
    
    if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene);
    if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene);
}

start
{
    return old.activeScene == "Menu" && current.activeScene == "Office";
}

split
{
    return old.loadingScene == "Office" && current.loadingScene == "End1";
}

reset
{
    return old.loadingScene == "Menu" && current.loadingScene != "Menu";
}