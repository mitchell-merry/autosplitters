// couldn't get unityasl to work with this game for the life of me
// and there's no static references to anything 
// if it works it works
state("Granny 3", "1.1.2")
{
	// not really but good enough
	bool cursorVisible: "GameAssembly.dll", 0xC21D38, 0x58, 0x3A8;

	// current unity scenes
	string128 loadingScene: "UnityPlayer.dll", 0x13E6100, 0x18, 0x0, 0xC, 0x10;
	string128 activeScene:  "UnityPlayer.dll", 0x13E6100, 0x2C, 0x0, 0xC, 0x10;
}

startup
{
	vars.Log = (Action<object>)(output => print("[G3-ASL] " + output));
	vars.TimerModel = new TimerModel { CurrentState = timer };

	vars.SplashScreenScene = "SplashScreen.unity"; // useless but including for completeness
	vars.MenuScene = "Menu.unity";
	vars.MainScene = "Scene.unity";

	vars.ItemLabels = new Dictionary<string, string>()
	{
		{"accelerator", "Accelerator"},
		{"bridgecrank", "Bridge Crank"},
		{"coconut", "Coconut"},
		{"coin", "Coin"},
		{"crowbar", "Crowbar"},
		{"dooractivator", "Door Activator"},
		{"electricswitch", "Electric Switch"},
		{"firewood", "Firewood"},
		{"gatefuse", "Gate Fuse"},
		{"gencable", "Generator Cable"},
		{"matches", "Matches"},
		{"padlockkey", "Padlock Key"},
		{"planka", "Plank"},
		{"safekey", "Safe Key"},
		{"shedkey", "Shed Key"},
		{"shotgun", "Shotgun"},
		{"slingshot", "Slingshot"},
		{"teddy", "Teddy Bear"},
		{"trainkey", "Train Key"},
		{"vas", "Vase 1"},                  // TODO figure out which vase is which (left/right)
		{"vas2", "Vase 2"},
		{"weaponkey", "Weapon Key"},
	};

	vars.ItemOffsets = new Dictionary<string, int>()
	{
		{"gatefuse", 0x48},
		{"shotgun", 0x54},
		{"teddy", 0x64},
		{"matches", 0x70},
		{"firewood", 0x7C},
		{"bridgecrank", 0x88},
		{"planka", 0x94},
		{"safekey", 0xA4},
		{"slingshot", 0xB4},
		{"vas", 0xC4},
		{"vas2", 0xD0},
		{"shedkey", 0xDC},
		{"padlockkey", 0xE8},
		{"gencable", 0xF4},
		{"coconut", 0x100},
		{"weaponkey", 0x10C},
		{"coin", 0x118},
		{"electricswitch", 0x124},
		{"trainkey", 0x130},
		{"accelerator", 0x13C},
		{"dooractivator", 0x148},
		{"crowbar", 0x154},
	};

	// Any% Glitchless Practice Preset 3
	// TODO this is really tedious to change for each category, fix that
	vars.DefaultSettings = new List<string>() { 
		"gatefuse", "gencable", "weaponkey", "slingshot", "crowbar", "shedkey", "bridgecrank"
	};

	settings.Add("reset_ongameclose", true, "Reset the autosplitter automatically when the game closes.");
	settings.Add("item_pickup", true, "Split on item pickup:");

	vars.ItemsGot = new Dictionary<string, bool>();
	vars.ItemWatchers = new MemoryWatcherList();
	foreach(string key in vars.ItemLabels.Keys)
	{
		vars.ItemsGot.Add(key, false);
		vars.ItemWatchers.Add(
			new MemoryWatcher<bool>(
				// InventorySystem - may break
				new DeepPointer("GameAssembly.dll", 0xC21D38, 0x50, 0x6EC, 0x8, 0x1C, 0x24, 0x18,
				vars.ItemOffsets[key])
			) { Name = key }
		);

		settings.Add(key, vars.DefaultSettings.Contains(key), vars.ItemLabels[key], "item_pickup");
	}
}

init {
	var mms = modules.First().ModuleMemorySize;

	print(mms.ToString("X"));
	// there are other versions which people have run that I don't have my hands on just yet (1.0.2/1.1)
	switch(mms) {
		case 0xA0000:
			version = "1.1.2";
			break;
		default:
			version = "Unknown. Contact diggitydingdong#3084 on discord to support this version.";
			break;
	}
}

update
{
	vars.ItemWatchers.UpdateAll(game);

	// watch for changes
	foreach(string key in vars.ItemLabels.Keys)
	{
		if(vars.ItemWatchers[key].Changed) 
		{
			vars.Log("Has " + vars.ItemLabels[key] + " [got: " + vars.ItemsGot[key] + "]: " + vars.ItemWatchers[key].Old.ToString() + " -> " + vars.ItemWatchers[key].Current.ToString());
		}
	}

	if(old.cursorVisible != current.cursorVisible)
	{
		vars.Log("cursorVisible: " + old.cursorVisible.ToString() + " -> " + current.cursorVisible.ToString() + " [" + current.loadingScene + "]" + " [" + current.activeScene + "]");
	}
}

start
{
	return !old.cursorVisible && current.cursorVisible
		&& current.activeScene == vars.MainScene		// condition is briefly satisfied after returning to the menu, 
		&& current.loadingScene == vars.MainScene; 		// so ensuring that we're in the main scene
}

split
{
	// Split when an item is picked up
	foreach(string key in vars.ItemLabels.Keys)
	{
		if(!vars.ItemsGot[key]					// if we haven't already picked this item up
			&& !vars.ItemWatchers[key].Old		// and we just picked it up
			&& vars.ItemWatchers[key].Current) 
		{
			vars.ItemsGot[key] = true;

			if(settings[key])
			{
				return true;
			}
		}
	}

	return false;
}

reset
{
	// auto-reset if you return to main menu
	return current.loadingScene == vars.MenuScene && current.activeScene == vars.MainScene;
}

onReset
{
	// mark everything as not picked up yet on reset
	foreach(string key in vars.ItemLabels.Keys) vars.ItemsGot[key] = false;
}

exit
{
	if(settings["reset_ongameclose"]) vars.TimerModel.Reset();
}