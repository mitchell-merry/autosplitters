state("DevilCatcherVer2.3") 
{
	string128 loading: "UnityPlayer.dll", 0xFF1CD0, 0x18, 0x0, 0xC, 0xD;
	string128 active:  "UnityPlayer.dll", 0xFF1CD0, 0x2C, 0x0, 0xC, 0xD;
}

startup
{/*
	MainMenu
	Level1
	DevilBoss
	Level2
	GodBoss
	*/
	vars.MainMenu = "MainMenu.unity";
	vars.Level1 = "Level1.unity";

	vars.Levels = new Dictionary<string, string>()
	{
		{ vars.Level1, "Level 1" },
		{ "DevilBoss.unity", "Devil Boss" },
		{ "Level2.unity", "Level 2" },
		{ "GodBoss.unity", "God Boss" },
	};

	settings.Add("level", true, "Split on level complete");
	foreach(string key in vars.Levels.Keys) 
	{
		settings.Add(key, false, vars.Levels[key], "level");
	}
}

update
{
	if(old.loading != current.loading) print("loading: " + old.loading + " -> " + current.loading);
	if(old.active != current.active) print("active: " + old.active + " -> " + current.active);
}

start
{
	return old.active == vars.MainMenu && current.active == vars.Level1;
}

split
{
	return old.loading != current.loading && settings[current.loading];
}

isLoading
{
	return current.loading != current.active;
}

reset
{
	return old.loading != current.loading && current.loading == vars.MainMenu;
}