state("JANITOR BLEEDS") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Janitor Bleeds";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    vars.CompletedSplits = new Dictionary<string, bool>();
    settings.Add("split", true, "Split on");
    settings.Add("split_FIND HELP", false, "Enter the arcade");
    settings.Add("split_entity", false, "Kill the Entity");
    settings.Add("split_source", false, "Kill the Source");
    settings.Add("split_end", true, "Game End");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["checkpoint"] = mono.Make<int>("GameManager", "instance", "LastCheckpoint", "checkpointID");
        // 35 - ??
        // 38 - ??
        // 5 - power room after first arcade? for vent? at the table? what?
        // 16 - the office
        // 17 - the office hallway

        vars.Helper["state"] = mono.Make<int>("MenuManager", "instance", "currentGameState");

        // CUSTOM

        vars.Helper["hasMoved"] = mono.Make<bool>("LevelManager", "hasMoved");
        vars.Helper["hasFinished"] = mono.Make<bool>("LevelManager", "hasFinished");
        vars.Helper["objective"] = mono.MakeString("LevelManager", "currentObjective");
        vars.Helper["objectiveId"] = mono.Make<long>("LevelManager", "currentObjetiveId");
        vars.Helper["entityDied"] = mono.Make<bool>("LevelManager", "entityDied");
        vars.Helper["sourceDied"] = mono.Make<bool>("LevelManager", "sourceDied");


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

    vars.Log(current.state);
    vars.Log(current.checkpoint);
    vars.Log(current.hasMoved);
    vars.Log(current.hasFinished);
    vars.Log(current.objective);
    vars.Log(current.objectiveId);
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
    if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

    vars.Watch("checkpoint");
    vars.Watch("hasMoved");
    vars.Watch("hasFinished");
    vars.Watch("objective");
    vars.Watch("objectiveId");
    vars.Watch("entityDied");
    vars.Watch("sourceDied");
}

start
{
    return current.activeScene == "Level"
        && current.checkpoint == 35 // beginning?
        && !old.hasMoved
        && current.hasMoved;
}

split
{
    if (old.objective != current.objective && vars.CheckSplit("split_" + old.objective))
    {
        return true;
    }

    if (!old.entityDied && current.entityDied && vars.CheckSplit("split_entity"))
    {
        return true;
    }

    if (!old.sourceDied && current.sourceDied && vars.CheckSplit("split_source"))
    {
        return true;
    }

    if (!old.hasFinished && current.hasFinished && vars.CheckSplit("split_end"))
    {
        return true;
    }
}

isLoading
{
    return current.loadingScene != current.activeScene
        || current.state == 0
        || current.state == 2;
}