state("Poly Bridge 3") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Poly Bridge 3";
    vars.Helper.Settings.CreateFromXml("Components/PolyBridge3.Settings.xml");

    vars.Level1s = new List<string>() {
        "LEVEL_900", "LEVEL_001"
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
    return old.state == 2 && current.state == 3 && vars.Level1s.Contains(current.levelName);
}

split
{
    return settings["level"]
        && old.levelName != current.levelName;
    //     && settings.ContainsKey("level_" + old.levelName)
    //     && settings["level_" + old.levelName];
}