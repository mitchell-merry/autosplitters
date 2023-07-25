state("the ball pit") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "The Ball Pit";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    settings.Add("scene_McDongs", false, "Split on falling down the hole.");
}

init
{
    vars.ReadSceneName = (Func<IntPtr, string>)(scene => {
        return vars.Helper.ReadString(256, ReadStringType.UTF8, scene + 0x38);
    });

    current.activeScene = current.loadingScene = "";
}

update
{
    current.activeScene = vars.ReadSceneName(vars.Helper.Scenes.Active.Address);
    current.loadingScene = vars.ReadSceneName(vars.Helper.Scenes.Loaded[0].Address);
}

start
{
    return old.activeScene == "Menu" && current.activeScene == "McDongs";
}

split
{
    if (settings["scene_McDongs"] && old.loadingScene != current.loadingScene && old.loadingScene == "McDongs")
    {
        return true;
    }
}

reset
{
    return old.loadingScene != current.activeScene && current.activeScene == "Menu";
}

isLoading
{
    return current.activeScene != current.loadingScene;
}