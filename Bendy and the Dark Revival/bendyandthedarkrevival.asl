state("Bendy and the Dark Revival") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Bendy and the Dark Revival";
	vars.Helper.AlertLoadless();

	// requested by community
	settings.Add("remove_paused", false, "Pause timer when the game is paused.");
	
	vars.FakeLoads = new List<string>() { "LOCATION_S107_FACTORY_LOCKERS", "LOCATION_S107_FACTORY_ACCESS_ENTRANCE" };
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gm = mono["GameManager"];
		vars.Helper["zone"] = mono.MakeString(gm, "m_Instance", "Player", "CurrentZone");
		vars.Helper["gm"] = mono.Make<IntPtr>(gm, "m_Instance");
		vars.Helper["GameState"] = mono.Make<int>(gm, "m_Instance", "GameState");
		vars.Helper["PauseMenuActive"] = mono.Make<bool>(gm, "m_Instance", "UIManager", "m_UIGameMenu", "IsActive");

		return true;
	});
}

onStart
{
	timer.IsGameTimePaused = settings["remove_paused"] && current.IsPaused;
}

update
{
	current.IsLoadingSection = vars.Helper.Read<IntPtr>(current.gm + 0xD0) != IntPtr.Zero;
	current.IsPaused = current.PauseMenuActive && current.GameState == 4;
}

isLoading
{
	if (settings["remove_paused"] && current.IsPaused) return true;

	return current.IsLoadingSection && !vars.FakeLoads.Contains(current.zone);
}