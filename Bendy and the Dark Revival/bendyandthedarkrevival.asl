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

isLoading
{
	if (settings["remove_paused"] && current.IsPaused) return true;

	return current.IsLoadingSection;
}