state("pogo") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Pogo3D";
    vars.Helper.LoadSceneManager = true;
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var pgm = mono["PogoGameManager", 1];
        var ld = mono["LevelDescriptor"];
        vars.Helper["level"] = mono.Make<int>(pgm, "GameInstance", pgm["RespawnLevel"], ld["BuildIndex"]);
        vars.Helper["startTime"] = mono.Make<float>(pgm, "GameInstance", pgm["GameStartTime"]);
        vars.Helper["finalTime"] = mono.Make<float>(pgm, "FinalTime");
        return true;
    });
}

update
{
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;
}

start
{
    return old.startTime < current.startTime;
}

split
{
    return (old.level < current.level && (current.level == 4 || current.level == 6))
        || old.finalTime != current.finalTime;
}

reset
{
    return old.loadingScene != current.loadingScene && current.loadingScene == "MainMenu";
}