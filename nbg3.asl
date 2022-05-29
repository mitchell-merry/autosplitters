state("Walls Closing In HDRP")
{
	string32 loadingScene: "UnityPlayer.dll", 0x1545C30, 0x28, 0x0, 0x10, 0xF;
	string32 activeScene: "UnityPlayer.dll", 0x1545C30, 0x50, 0x0, 0x10, 0xF;
}

startup
{	
	vars.MainMenu = "Main Menu.unity";
	vars.KidnapFlashback = "Kidnap Flashback.unity";
	vars.Scenes = new List<string>()
	{
		"New Prologue", "The Farmhouse", "Interrogation", "The Hood", "End Credits"
	};

	vars.Suffix = ".unity";

	settings.Add("scenes", true, "Split on entering level.");
	foreach(string scene in vars.Scenes)
	{
		settings.Add(scene + vars.Suffix, scene != "The Hood", scene, "scenes");
	}
}

start 
{
	return current.activeScene == vars.KidnapFlashback && old.activeScene== vars.MainMenu;    
}

reset 
{
	return current.loadingScene != old.loadingScene && current.loadingScene == vars.MainMenu;
}

split 
{
	if(current.loadingScene != old.loadingScene)
	{
		return settings[current.loadingScene];
	}
}

isLoading 
{
	return current.activeScene != current.loadingScene;
}

