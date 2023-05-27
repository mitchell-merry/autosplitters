state("polybridge") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Poly Bridge";
    vars.Helper.Settings.CreateFromXml("Components/PolyBridge.Settings.xml");

    vars.Level1s = new List<string>() {
        "Easy_001", "Easy_006", "LoopBack4", "Medium_007_MonsterTruckJump", "DoubleDouble", "601CantWait", "701TrapDoors", "801Raiders"
    };
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["levelName"] = mono.MakeString("LevelManager", 1, "instance", "currentActiveLevel", "levelName");
        return true;
    });
}

start
{
    // caveat: if you leave a level 1 and then go right back into it it will not start
    // this is because there is no level change to detect
    // if the unity scenemanager was working for this game this wouldn't be an issue,
    // but it isn't, so it is
    return old.levelName != current.levelName && vars.Level1s.Contains(current.levelName);
}

split
{
    return settings["level"]
        && old.levelName != current.levelName
        && settings.ContainsKey("level_" + old.levelName)
        && settings["level_" + old.levelName];
}