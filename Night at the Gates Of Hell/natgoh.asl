state("Night at the Gates of Hell") {}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "NatGoH";
	vars.Helper.LoadSceneManager = true;

	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gm = mono["GameManager"];
		vars.Helper["GameState"] = mono.Make<int>(gm, "instance", "currentGameState");

		return true;
	});
}

onStart
{
	vars.Log(vars.Helper["GameState"]);}

isLoading
{
	return current.GameState == 2;
}