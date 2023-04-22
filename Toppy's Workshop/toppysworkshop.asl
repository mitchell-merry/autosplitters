state("Toppy's Workshop") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Toppy's Workshop";
	vars.Helper.LoadSceneManager = true;
	// vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
        vars.Helper["time"] = mono.Make<float>("MANAGER_Game", "instance", "time");
        vars.Helper["timerRunning"] = mono.Make<bool>("MANAGER_Game", "instance", "timerRunning");
        vars.Helper["dead"] = mono.Make<bool>("PLAYER", "instance", "dead");
		return true;
	});
}

start
{
    return old.time == 0 && current.time > old.time;
}

split
{
    return old.timerRunning && !current.timerRunning;
}

reset
{
    return !old.dead && current.dead;
}

gameTime
{
    return TimeSpan.FromSeconds(current.time);
}