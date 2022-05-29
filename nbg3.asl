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

	// vars.Logos = "logos.unity";
	// vars.MainMenu = "Main Menu.unity";
	// vars.KidnapFlashback = "Kidnap Flashback.unity";
	// vars.NewPrologue = "New Prologue.unity";
	// vars.TheFarmhouse = "The Farmhouse.unity";
	// vars.Interrogation = "Interrogation.unity";
	// vars.TheHood = "The Hood.unity";
	// vars.EndCredits = "End Credits.unity";

	// vars.Splits = new string[][] {
	// 	new string[] { vars.KidnapFlashback, vars.NewPrologue },	// Zomb's "Prologue" split
	// 	new string[] { vars.NewPrologue, vars.TheFarmhouse },		// Zomb's "Basement" split
	// 	new string[] { vars.TheFarmhouse, vars.Interrogation },		// Zomb's "Farm" split
	// 	new string[] { vars.TheHood, vars.EndCredits }				// Zomb's "End" split
	// };
}

start 
{
	return current.activeScene == vars.KidnapFlashback && old.activeScene== vars.MainMenu;    
}

reset 
{
	return current.loadingScene != old.loadingScene && current.loadingScene == vars.MainMenu;
}

split {
	if(current.loadingScene != old.loadingScene)
	{
		return settings[current.loadingScene];
	}

	// if(!current.loadingScene.Equals(old.loadingScene)) {
	// 	print("Prev: " + old.loadingScene);
	// 	print("Curr: " + current.loadingScene);


	// 	for(int i = 0; i < vars.Splits.Length; i++) {
	// 		if(old.loadingScene.Equals(vars.Splits[i][0]) && current.loadingScene.Equals(vars.Splits[i][1])) {
	// 			return true;
	// 		}
	// 	}
	// }
}

isLoading 
{
	return current.activeScene != current.loadingScene;
}

