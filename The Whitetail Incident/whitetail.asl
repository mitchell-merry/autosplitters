// This autosplitter was kindly written in assistance with Ero

state("The Whitetail Incident") {}

startup { 
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "TWI";
	vars.Helper.LoadSceneManager = true;
	vars.AlertLoadless();

	settings.Add("startOn", false, "Start on after the first cutscene, not before.")''
	settings.Add("sceneSplits", true, "Split on:");
	settings.Add("Map01", false, "Reaching ritual cutscene", "sceneSplits");
	settings.Add("Map02", false, "Interacting with Johnathon at the ritual", "sceneSplits");
	settings.Add("Map03", false, "Reaching Johnathon", "sceneSplits");
	settings.Add("Map04(Boss)", true, "Killing Johnathon (End)", "sceneSplits");
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	// if(current.activeScene != old.activeScene) vars.Log("a: " + old.activeScene + ", " + current.activeScene);
	// if(current.loadingScene != old.loadingScene) vars.Log("l: " + old.loadingScene + ", " + current.loadingScene);
}

isLoading
{
    return current.activeScene != current.loadingScene;
}

start
{
	return settings[startOn]
		? old.activeScene == "Cutscene01" && current.activeScene == "Cutscene02"
		: old.activeScene == "MainMenu" && current.activeScene == "Cutscene01"
}

split
{
	return old.loadingScene != current.loadingScene &&
		settings.ContainsKey(old.loadingScene) && settings[old.loadingScene]
		&& current.loadingScene != "MainMenu";
}