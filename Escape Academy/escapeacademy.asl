state("Escape Academy") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");

	vars.Helper.AlertLoadless();
}

init
{
	print("Escape Academy detected.");

	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var mgm = mono["Escape.Metagame.MetagameManager"];
		vars.Helper["MGMState"] = mono.Make<int>(mgm, "_instance", "_currentMetaGameState");
		vars.Helper["AsyncLoading"] = mono.Make<bool>(mgm, "_instance", "sceneLevelManager", "_asyncLoadingLevel");

		var lsm = mono["Escape.Metagame.LevelSelect.LevelSelectManager"];
		vars.Helper["LSState"] = mono.Make<int>(lsm, "Instance", "_currentLevelSelectState");

		var rm = mono["Escape.Rooms.RoomManager"];
		vars.Helper["RoomHasStarted"] = mono.Make<bool>(rm, "Instance", "RoomHasStarted");

		return true;
	});
}

update
{
	// intro / outro states
	current.LSLoading = current.LSState == 0 || current.LSState == 4;
	current.MGMLoading = current.MGMState == 1;
}

isLoading
{
	return (current.AsyncLoading || (current.LSLoading && current.MGMState == 3))
	   && !(current.MGMLoading && current.RoomHasStarted);    // the dialogue portion before a level
}
