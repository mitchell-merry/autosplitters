state("pogo") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Pogo3D";
    vars.Helper.LoadSceneManager = true;

    vars.CompletedSplits = new HashSet<string>();

    settings.Add("level", true, "Split on beating level");
    settings.Add("level_4", false, "The Swamp / Throne Room", "level");
    settings.Add("level_6", false, "Sewers", "level");
    settings.Add("scene_Credits", true, "Yard", "level");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var pgm = mono["PogoGameManager", 1];
        var ld = mono["LevelDescriptor"];
        vars.Helper["level"] = mono.Make<int>(pgm, "GameInstance", pgm["RespawnLevel"], ld["BuildIndex"]);
        vars.Helper["startTime"] = mono.Make<float>(pgm, "GameInstance", pgm["GameStartTime"]);
        return true;
    });

    vars.ReadSceneName = (Func<IntPtr, string>)(scene => {
        // this seems to work best?
        string name = vars.Helper.ReadString(256, ReadStringType.UTF8, scene + 0x38);
        return name == "" ? null : name;
    });

    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || !vars.CompletedSplits.Add(key)
        ) {
            return false;
        }

        vars.Log("Completed: " + key);
        return true;
    });
}

update
{
    current.scene = vars.ReadSceneName(vars.Helper.Scenes.Loaded[0].Address);
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
}

start
{
    return old.startTime < current.startTime;
}

split
{
    if (old.level < current.level && vars.CheckSplit("level_" + current.level))
    {
        return true;
    }

    return old.scene != current.scene && vars.CheckSplit("scene_" + current.scene);
}

reset
{
    return old.scene != current.scene && current.scene == "MainMenu";
}