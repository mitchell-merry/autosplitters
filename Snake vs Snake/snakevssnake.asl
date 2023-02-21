state("Snake vs Snake") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Snake vs Snake";
	vars.Helper.LoadSceneManager = true;
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gg = "GameGlobals";
		vars.Helper["timerRunning"] = mono.Make<bool>(gg, "isTimerRunning");
		vars.Helper["time"] = mono.Make<float>(gg, "totalPlayTimeLevelsSpeedRun");
		vars.Helper["gameState"] = mono.Make<int>(gg, "gameState");
		vars.Helper["levelResult"] = mono.Make<int>(gg, "levelResult");

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
	return old.gameState == 1 && current.gameState == 2 // running -> levelCompleted
	    && current.levelResult == 1;                    // success
}