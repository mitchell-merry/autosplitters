state("DOOMTheDarkAges") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "DOOM: The Dark Ages";
    // vars.Helper.Settings.CreateFromXml("Components/TEMPLATE.Settings.xml");
    
    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });
    
    vars.CompletedSplits = new HashSet<string>();
    
    vars.Helper.AlertLoadless();

    //creates text components for variable information
	vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
	        var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
	        var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
	        if (textSetting == null)
	        {
	        var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
	        var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
	        timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));
	
	        textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
	        textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
	        }
	
	        if (textSetting != null)
	        textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
    });

    //Parent setting
	settings.Add("Variable Information", true, "Variable Information");
	//Child settings that will sit beneath Parent setting
    settings.Add("Loading", false, "Current Loading", "Variable Information");
    settings.Add("Mission", false, "Current Mission", "Variable Information");
}

init
{
    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key =>
    {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || !vars.CompletedSplits.Add(key)
        ) {
            return false;
        }

        vars.Log("Completed: " + key);
        return true;
    });

    vars.idGameSystemLocal = vars.Helper.ScanRel(0x6, "FF 50 40 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0");
    vars.Log("Found idGameSystemLocal at 0x" + vars.idGameSystemLocal.ToString("X"));

    vars.Watchers = new MemoryWatcherList() {
        // enum GameState {
        //   GAME_STATE_MAIN_MENU = 0,
        //   GAME_STATE_LOADING = 1,
        //   GAME_STATE_INGAME = 2,
        // }
        new MemoryWatcher<int>(
            new DeepPointer(
                vars.idGameSystemLocal + 0x40
            )
        ) { Name = "gameState" },
        new StringWatcher(
            new DeepPointer(
                vars.idGameSystemLocal + 0xA8 + 0x18,
                0x0
            ),
            0x100
        ) { Name = "mission" }
    };
}

update
{
    IDictionary<string, object> currdict = current;
    
    // read the values, place them all in current
    vars.Watchers.UpdateAll(game);
    foreach (var watcher in vars.Watchers)
    {
        currdict[watcher.Name] = watcher.Current;
    }

    //Prints the camera target to the Livesplit layout if the setting is enabled
        if(settings["Loading"]) 
    {
        vars.SetTextComponent("GameState:",current.gameState.ToString());
    }

            //Prints the camera target to the Livesplit layout if the setting is enabled
        if(settings["Mission"]) 
    {
        vars.SetTextComponent(" ",current.mission.ToString());
    }
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log("mission: " + current.mission);
}

isLoading
{
    return current.gameState == 1;
}

start
{
    if (old.mission == "game/shell/shell" && current.mission != "game/shell/shell")
    {
        timer.IsGameTimePaused = true;
        return true;
    }
}

split
{
    return old.mission != current.mission && current.mission != "game/shell/shell";
}
