state("Granny 3")
{
    // true in the main menu
    bool cursorVisible: "GameAssembly.dll", 0xC21D38, 0x58, 0x3A8;

    // current unity scenes, final 0x10 is to chop off unnecessary initial characters
    string128 loadingScene: "UnityPlayer.dll", 0x13E6100, 0x18, 0x0, 0xC, 0x10;
    string128 activeScene:  "UnityPlayer.dll", 0x13E6100, 0x2C, 0x0, 0xC, 0x10;
}

startup
{
    vars.Log = (Action<object>)(output => print("[G3-ASL] " + output));

    vars.SplashScreenScene = "SplashScreen.unity"; // useless but including for completeness
    vars.MenuScene = "Menu.unity";
    vars.MainScene = "Scene.unity";

    vars.ItemLabels = new Dictionary<string, string>()
    {
        {"gatefuse", "Gate Fuse"},
        {"shotgun", "Shotgun"},
        {"teddy", "Teddy Bear"},
        {"matches", "Matches"},
        {"firewood", "Firewood"},
        {"bridgecrank", "Bridge Crank"},
        {"planka", "Plank"},
        {"safekey", "Safe Key"},
        {"slingshot", "Slingshot"},
        {"vas", "Vase 1"},
        {"vas2", "Vase 2"},
        {"shedkey", "Shed Key"},
        {"padlockkey", "Padlock Key"},
        {"gencable", "Generator Cable"},
        {"coconut", "Coconut"},
        {"weaponkey", "Weapon Key"},
        {"coin", "Coin"},
        {"electricswitch", "Electric Switch"},
        {"trainkey", "Train Key"},
        {"accelerator", "Accelerator"},
        {"dooractivator", "Door Activator"},
        {"crowbar", "Crowbar"},
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
    vars.DefaultSettings = new List<string>() { 
        "gatefuse", "gencable", "weaponkey", "slingshot", "crowbar", "shedkey", "bridgecrank"
    };

    vars.ItemsGot = new Dictionary<string, bool>();
    vars.ItemWatchers = new MemoryWatcherList();
    foreach(string key in vars.ItemLabels.Keys)
    {
        vars.ItemsGot.Add(key, false);
        vars.ItemWatchers.Add(
            new MemoryWatcher<bool>(
                // InventorySystem - may break
                new DeepPointer("UnityPlayer.dll", 0x013C1A7C, 0x60, 0x84, 0xC, 0x3C,
                vars.ItemOffsets[key])
            ) { Name = key }
        );

        settings.Add(key, vars.DefaultSettings.Contains(key), vars.ItemLabels[key]);
    }
}

init { }

update
{
    vars.ItemWatchers.UpdateAll(game);

    foreach(string key in vars.ItemLabels.Keys)
    {
        // watchin
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
        && current.activeScene == vars.MainScene; // condition is briefly satisfied after returning to the menu, so ensuring that we're in the main scene
}

split
{
    // Split when an item is picked up
    foreach(string key in vars.ItemLabels.Keys)
    {
        if(!vars.ItemsGot[key] && !vars.ItemWatchers[key].Old && vars.ItemWatchers[key].Current) 
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
    foreach(string key in vars.ItemLabels.Keys) vars.ItemsGot[key] = false;
}