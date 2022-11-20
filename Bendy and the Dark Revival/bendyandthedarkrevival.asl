state("Bendy and the Dark Revival") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Bendy and the Dark Revival";
	vars.Helper.AlertLoadless();

	// requested by community
	settings.Add("remove_paused", false, "Pause timer when the game is paused.");
	
	vars.FakeLoads = new List<string>() { "LOCATION_S107_FACTORY_LOCKERS" };
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gm = mono["GameManager"];
		// vars.Helper["IsPaused"] = mono.Make<bool>(gm, "m_Instance", "IsPaused");
		vars.Helper["zone"] = mono.MakeString(gm, "m_Instance", "Player", "CurrentZone");
		// hashset of currently loading sections, 0x30 is the _count field of the HashSet
		vars.Helper["SectionLoadingCount"] = mono.Make<int>(gm, "m_Instance", "SectionManager", "m_SectionsLoading", 0x30);

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
	current.IsLoadingSection = current.SectionLoadingCount > 0;
	current.IsPaused = current.PauseMenuActive && current.GameState == 4;
}

isLoading
{
	if (settings["remove_paused"] && current.IsPaused) return true;

	return current.IsLoadingSection && !vars.FakeLoads.Contains(current.zone);
}