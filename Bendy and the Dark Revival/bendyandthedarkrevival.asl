state("Bendy and the Dark Revival") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Bendy and the Dark Revival";
	vars.Helper.AlertLoadless();

	// requested by community
	settings.Add("remove_paused", false, "Pause timer when the game is paused.");
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gm = mono["GameManager"];
		vars.Helper["asyncLoader"] = mono.Make<IntPtr>(gm, "m_Instance", "m_AsyncLoader");
		vars.Helper["GameState"] = mono.Make<int>(gm, "m_Instance", "GameState");
		vars.Helper["PauseMenuActive"] = mono.Make<bool>(gm, "m_Instance", "UIManager", "m_UIGameMenu", "IsActive");
		vars.Helper["GMIsPaused"] = mono.Make<bool>(gm, "m_Instance", "IsPaused");
		vars.Helper["IsPauseReady"] = mono.Make<bool>(gm, "m_Instance", "IsPauseReady");

		return true;
	});
}

update
{
	// this class is instantiated on every load
	current.IsLoadingSection = current.asyncLoader != null;
	current.IsPaused = current.PauseMenuActive && current.GameState == 4 && current.GMIsPaused && current.IsPauseReady;
}

isLoading
{
	if (settings["remove_paused"] && current.IsPaused) return true;

	return current.IsLoadingSection;
}