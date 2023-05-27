state("Poly Bridge 2") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Poly Bridge 2";
    vars.Helper.Settings.CreateFromXml("Components/PolyBridge2.Settings.xml");

    vars.Level1s = new List<string>() {
        "LEVEL_TEN_METER_SIMPLE_BRIDGE",
        "LEVEL_UNITY",
        "LEVEL_LOOP_HOLE",
        "LEVEL_EDGY",
        "LEVEL_BREAK_CHECK", 
        "LEVEL_EARTHQUAKE",
        "LEVEL_B1-01",
        "LEVEL_B2-01"
    };
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["levelName"] = mono.MakeString("Campaign", "m_CurrentLevel", "m_DisplayNameLocID");
        vars.Helper["state"] = mono.Make<int>("GameStateManager", "m_GameState");
        return true;
    });
}

onStart
{
    vars.Log(current.levelName);
    vars.Log(current.state);
}

update
{
    vars.Watch("levelName");
    vars.Watch("state");
}

start
{
    return old.state == 3 && current.state == 4 && vars.Level1s.Contains(current.levelName);
}

split
{
    return settings["level"]
        && old.levelName != current.levelName
        && settings.ContainsKey("level_" + old.levelName)
        && settings["level_" + old.levelName];
}