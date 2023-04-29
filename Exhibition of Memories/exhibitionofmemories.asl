state("Exhibition of Memories") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Exhibition of Memories";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	vars.Helper.Settings.CreateFromXml("Components/ExhibitionOfMemories.Settings.xml");
}

init
{
    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off
        if (!settings.ContainsKey(key)
          || !settings[key]
        ) {
            return false;
        }

        vars.Log("Completed: " + key);
        return true;
    });
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;
}

start
{
    return old.activeScene == "MainMenu" && current.activeScene == "Intro";
}

isLoading
{
    return current.loadingScene != old.loadingScene;
}

split
{
    if (old.loadingScene != current.loadingScene) {
        var key = "scene_" + old.loadingScene;
        if (vars.CheckSplit(key)) {
            return true;
        }
    }
}