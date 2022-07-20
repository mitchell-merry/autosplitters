// THIS IS MY DEBUGGING VERSION OF THE ASL

state("Escape Academy") { }

startup
{
	vars.Log = (Action<object>)(output => print("[Escape Academy] " + output.ToString()));

	var bytes = File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin");
	var type = Assembly.Load(bytes).GetType("ASLHelper.Unity");
	vars.Helper = Activator.CreateInstance(type, timer, this);
	vars.Helper.LoadSceneManager = true;

	vars.GameStates = new string[] {
		"Init", "Loading", "MainMenu", "LevelSelect", "RoomReview",
		"Cutscene", "Lobby", "Pause", "Gameplay", "Chapter Card"
	};
}

init 
{
	print("Escape Academy detected.");

	vars.Helper.TryOnLoad = (Func<dynamic, bool>)(mono =>
	{
		vars.LogIfChanged = (Action<string>)(v => 
		{
			if(vars.Helper[v].Changed) vars.Log(v + ": " + vars.Helper[v].Old + " -> " + vars.Helper[v].Current);
		});

		var mgm = mono.GetClass("Escape.Metagame.MetagameManager");
		var slm = mono.GetClass("Escape.Metagame.SceneLevelManager");
		var lsm = mono.GetClass("Escape.Metagame.LevelSelect.LevelSelectManager");

		vars.Helper["currentMGState"] = mgm.Make<int>("_instance", "_currentMetaGameState");
		vars.Helper["LSState"] = lsm.Make<int>("Instance", "_currentLevelSelectState");
		vars.Helper["_loadSceneFlag"] = mgm.Make<bool>("_instance", "sceneLevelManager", slm["_loadSceneFlag"]);
		vars.Helper["_asyncLoadingLevel"] = mgm.Make<bool>("_instance", "sceneLevelManager", slm["_asyncLoadingLevel"]);

		// var mmm = mono.GetClass("Escape.Metagame.MainMenu.MainMenuManager");
		// var sgfm = mono.GetClass("Escape.Metagame.MainMenu.SelectGameFileManager");

		// var edm = mono.GetClass("Escape.Metagame.Metadata.EscapeDataManager");

		// vars.Helper["userLoaded"] = edm.Make<bool>("Instance", "_userLoaded");

		var rm = mono.GetClass("Escape.Rooms.RoomManager");

		vars.Helper["RoomHasStarted"] = rm.Make<bool>("Instance", "RoomHasStarted");

		return true;
	});

	vars.Helper.Load();
}

update
{
	if (!vars.Helper.Update())
		return false;

	

	current.RoomHasStarted = vars.Helper["RoomHasStarted"].Current;
	current.AsyncLoading = vars.Helper["_asyncLoadingLevel"].Current;
	current.MGMState = vars.Helper["currentMGState"].Current;
	// intro / outro states
	current.LSLoading = vars.Helper["LSState"].Current == 0 || vars.Helper["LSState"].Current == 4;
	current.MGMLoading = vars.Helper["currentMGState"].Current == 1;

	vars.LogIfChanged("_asyncLoadingLevel");
	vars.LogIfChanged("_loadSceneFlag");
	vars.LogIfChanged("RoomHasStarted");
	vars.LogIfChanged("currentMGState");
	vars.LogIfChanged("LSState");
	if(vars.Helper["currentMGState"].Changed)
		vars.Log(String.Format("GS: {0} -> {1}",
			vars.GameStates[vars.Helper["currentMGState"].Old],
			vars.GameStates[vars.Helper["currentMGState"].Current]
		));
}

onStart
{
	vars.Log("RoomHasStarted: " + current.RoomHasStarted);
	vars.Log("_asyncLoadingLevel: " + vars.Helper["_asyncLoadingLevel"].Current);
}

isLoading
{
	return (current.AsyncLoading || (current.LSLoading && current.MGMState == 3))
		&& !(current.MGMLoading && current.RoomHasStarted);    // the dialogue portion before a level
}

exit
{
	vars.Helper.Dispose();
}

shutdown
{
	vars.Helper.Dispose();
}
