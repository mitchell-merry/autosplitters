state("Snake vs Snake") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Snake vs Snake";
	vars.Helper.LoadSceneManager = true;
	// vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gg = "GameGlobals";
		vars.Helper["timerRunning"] = mono.Make<bool>(gg, "isTimerRunning");
		vars.Helper["time"] = mono.Make<float>(gg, "totalPlayTimeLevelsSpeedRun");
		vars.Helper["gameState"] = mono.Make<int>(gg, "gameState");

		return true;
	});
}

start
{
	// start time if the timer in-game begins from 0
	return !old.timerRunning && current.timerRunning && current.time == 0;
}

split
{
	// running -> levelCompleted
	return old.gameState == 1 && current.gameState == 2;
}