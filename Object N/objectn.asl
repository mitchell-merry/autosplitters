state("ObjectN2") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Object N";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	vars.Maps = new Dictionary<string, string>() {
		{ "e1m1", "Level 1" },
		{ "e1m2", "Level 2" },
		{ "e1m3", "Level 3" },
		{ "e1m4", "Level 4" },
		{ "e1m5", "Level 5" },
		{ "e1m6", "Level 6" },
		{ "e1m7", "Level 7" },
		{ "e1m8", "Level 8" },
		{ "factory", "Factory" },
	};

	settings.Add("level_end", false, "Split on level end");
	foreach (var map in vars.Maps.Keys)
	{
		settings.Add(map, false, vars.Maps[map], "level_end");
	}
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		return true;
	});
}

onStart
{
	vars.Log(current.activeScene);
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
	return old.activeScene == "Menu" && current.activeScene == "e1m1";
}

split
{
	return old.loadingScene != current.loadingScene && settings.ContainsKey(old.loadingScene) && settings[old.loadingScene];
}

isLoading
{
	return current.activeScene != current.loadingScene;
}