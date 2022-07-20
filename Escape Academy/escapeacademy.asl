state("Escape Academy") { }

startup
{
	var bytes = File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin");
	var type = Assembly.Load(bytes).GetType("ASLHelper.Unity");
	vars.Helper = Activator.CreateInstance(type, timer, this);
}

init 
{
	print("Escape Academy detected.");

	vars.Helper.TryOnLoad = (Func<dynamic, bool>)(mono =>
	{
		var mgm = mono.GetClass("Escape.Metagame.MetagameManager");
		var slm = mono.GetClass("Escape.Metagame.SceneLevelManager");

		vars.Helper["currentMGState"] = mgm.Make<int>("_instance", "_currentMetaGameState");
		vars.Helper["_asyncLoadingLevel"] = mgm.Make<bool>("_instance", "sceneLevelManager", slm["_asyncLoadingLevel"]);

		var lsm = mono.GetClass("Escape.Metagame.LevelSelect.LevelSelectManager");
		vars.Helper["LSState"] = lsm.Make<int>("Instance", "_currentLevelSelectState");

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
}

isLoading
{
	return (current.AsyncLoading || current.LSLoading)
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
