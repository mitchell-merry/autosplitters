state("SkerRitual") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Sker Ritual";
    vars.Helper.AlertGameTime();

    settings.Add("round", true, "Split on reaching round");
    for (var i = 5; i <= 100; i += 5)
    {
        bool d = i == 100;
        settings.Add("round_" + i, d, "Round " + i, "round");
    }
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var ggmm = mono["GlobalGameModeManager", 1];
        var gmm = mono["GameModeManager"];
        
        vars.Helper["elapsedTime"] = ggmm.Make<float>(
            "_Instance"
            ,ggmm["CurrentGameModeManager"]
            ,gmm["m_ElapsedTime"]
        );

        var gwm = mono["GlobalWaveManager", 1];
        vars.Helper["round"] = gwm.Make<int>(
            "_Instance"
            ,gwm["m_CurrentRound"]
        );

        return true;
    });
}

split
{
    return old.round != current.round &&
           settings.ContainsKey("round_" + current.round) &&
           settings["round_" + current.round];
}

gameTime
{
    return TimeSpan.FromSeconds(current.elapsedTime);
}

isLoading
{
    return true;
}