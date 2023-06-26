state("Greylock-Win64-Shipping")
{
    // cheat table in repo describes these paths
    long ActiveZone: 0x56A6B60, 0x120, 0x410;
    int SpawnCount: 0x56A6B60, 0x120, 0x410, 0x510;       // total number of guys that spawn
    int BattleCountForUI: 0x56A6B60, 0x120, 0x410, 0x518; // number left
}

startup
{
    settings.Add("split_zone", true, "Split on completing a fight");
    settings.Add("split_zone_25", false, "Wind Temple", "split_zone");
    settings.Add("split_zone_20", false, "Ice Castle", "split_zone");
    settings.Add("split_zone_21", false, "Fire Temple", "split_zone");
    settings.Add("split_zone_30", true, "Final Fight", "split_zone");
}

split
{
    if (old.BattleCountForUI > current.BattleCountForUI 
        && current.BattleCountForUI <= 0
        && settings.ContainsKey("split_zone_" + old.SpawnCount)
        && settings["split_zone_" + old.SpawnCount]) {
            print("Yo? " + old.SpawnCount);
            return true;
        }
}