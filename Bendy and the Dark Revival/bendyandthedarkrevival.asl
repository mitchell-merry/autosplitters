state("Bendy and the Dark Revival") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Bendy and the Dark Revival";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	// requested by community
	settings.Add("remove_paused", false, "Pause timer when the game is paused.");
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gm = mono["GameManager"];
		vars.Helper["IsPaused"] = mono.Make<bool>(gm, "m_Instance", "IsPaused");
		vars.Helper["CurrentZone"] = mono.MakeString(gm, "m_Instance", "Player", "CurrentZone");
		// 0x20 is ID, state can't be found due to conflict of class names
		vars.Helper["PlayerState"] = mono.Make<int>(gm, "m_Instance", "Player", "m_State", 0x20);
		// hashset of currently loading sections, 0x30 is the _count field of the HashSet
		vars.Helper["SectionLoadingCount"] = mono.Make<int>(gm, "m_Instance", "SectionManager", "m_SectionsLoading", 0x30);

		return true;
	});
}

onStart
{
	timer.IsGameTimePaused = settings["remove_paused"] && current.IsPaused;
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

	current.IsLoadingSection = current.SectionLoadingCount > 0;
}

start
{
	// peek -> cutscene
	return old.PlayerState == 4 && current.PlayerState == 1
	    && current.CurrentZone == "LOCATION_S102_AUDREYS_OFFICE";
}

isLoading
{
	if (settings["remove_paused"] && current.IsPaused) return true;

	return current.IsLoadingSection;
}