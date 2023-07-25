state("Poly Bridge 3") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Poly Bridge 3";
    vars.Helper.AlertLoadless();
    vars.Helper.Settings.CreateFromXml("Components/PolyBridge3.Settings.xml");

    vars.CompletedSplits = new Dictionary<string, bool>();
    vars.Level1s = new List<string>() {
        "LEVEL_900", "LEVEL_001", "LEVEL_013", "LEVEL_030", "LEVEL_040", "LEVEL_061", "LEVEL_070", "LEVEL_101", "LEVEL_121", "LEVEL_080", "LEVEL_181", "LEVEL_161", "LEVEL_201"
    };
    
    vars.FinalLevels = new List<string>() {
        "LEVEL_011", "LEVEL_023", "LEVEL_075", "LEVEL_049", "LEVEL_069", "LEVEL_059", "LEVEL_110", "LEVEL_133", "LEVEL_090", "LEVEL_194", "LEVEL_170", "LEVEL_203"
    };
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["level"] = mono.MakeString("Campaign", "m_CurrentLevel", "m_DisplayNameLocID");
        vars.Helper["state"] = mono.Make<int>("GameStateManager", "m_GameState");
        vars.Helper["levelPassed"] = mono.Make<bool>("GameStateSim", "m_LevelPassed");
        return true;
    });

    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || vars.CompletedSplits.ContainsKey(key) && vars.CompletedSplits[key]
        ) {
            return false;
        }

        vars.CompletedSplits[key] = true;
        vars.Log("Completed: " + key);
        return true;
    });
}

onStart
{
    foreach(var split in new List<string>(vars.CompletedSplits.Keys))
    {
        vars.CompletedSplits[split] = false;
    }
}

update
{
    current.nonLoadingState = current.state != 7 ? current.state : current.nonLoadingState;

    var levelChanged = old.level != current.level;
    var goingToMenu = old.nonLoadingState == 5 && current.nonLoadingState == 2;

    if (settings["il"] && settings["il_reset"] && (levelChanged || goingToMenu)
    ) {
        vars.Helper.Timer.Reset();
    }
}

start
{
    var goingToLevel = old.state == 2 && current.state == 3;
    
    if (settings["il"])
        return goingToLevel || old.level != current.level; 

    return goingToLevel && vars.Level1s.Contains(current.level);
}

split
{   
    if (settings["il"])
        return !old.levelPassed && current.levelPassed;
    
    if (!settings["level"])
        return false;

    var goingToMenu = old.nonLoadingState == 5 && current.nonLoadingState == 2;

    if (vars.FinalLevels.Contains(current.level) && goingToMenu && current.levelPassed)
        return vars.CheckSplit("level_" + old.level);

    return settings["level"]
        && old.level != current.level
        && vars.CheckSplit("level_" + old.level);
}

isLoading
{
    return current.state == 7;
}