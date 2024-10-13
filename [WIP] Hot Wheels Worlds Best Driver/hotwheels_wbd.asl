state("Game")
{
    bool inGame: 0x4DEEB0;
    string32 scene: 0x4E8ED4;
    float igt: 0x4E8E40;
}

startup
{
    settings.Add("igt", false, "Use IL time.");
}

start
{
    return settings["igt"] && scene != "hub_s1" && old.igt < 0.01 && current.igt >= 0.01;
}

isLoading
{
    return settings["igt"] || !current.inGame;
}

gameTime
{
    if (!settings["igt"]) return;

    return TimeSpan.FromSeconds(current.igt);
}