state("Gang Beasts") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Gang Beasts";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

    vars.CompletedSplits = new Dictionary<string, bool>();
	vars.ResetSplits = (Action)(() => { foreach(var split in new List<string>(vars.CompletedSplits.Keys)) vars.CompletedSplits[split] = false; });

    settings.Add("stage", false, "Split on stage complete");
    settings.Add("stage_Grind", false, "Grind", "stage");
    settings.Add("stage_Incinerator", false, "Incinerator", "stage");
    settings.Add("stage_Roof", false, "Roof", "stage");
    settings.Add("stage_Subway", false, "Subway", "stage");
    settings.Add("wave", false, "Split on wave complete");
}

init
{
    vars.CheckSplit = (Func<string, bool, bool>)((key, checkSetting) => {
        // if we check the setting and it doesn't exist or it's off
        if (checkSetting && (!settings.ContainsKey(key) || !settings[key]))
        {
            return false;
        }

        // if we've done it already
        if (vars.CompletedSplits.ContainsKey(key) && vars.CompletedSplits[key]
        ) {
            return false;
        }

        vars.CompletedSplits[key] = true;
        vars.Log("Completed: " + key);
        return true;
    });

	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
        var GM_W = mono["GameMode_Waves"];
        vars.Helper["timer"] = mono.Make<float>("PauseManager", "gameManager", "internalActiveGameMode", GM_W["totalTime"]);
        vars.Helper["wave"] = mono.Make<int>("PauseManager", "gameManager", "internalActiveGameMode", GM_W["_roundCounter"]);

        /**
		 * Inactive = 0,
		 * ServerChangingScene = 1,
		 * WaitingForClientsToLoad = 2,
		 * GameSetup = 4,
		 * PreStartCountdown = 8,
		 * Active = 16,
		 * PostGame = 32,
		 * DisplayingScores = 64,
		 * GameEnded = 128
         */
        vars.Helper["state"] = mono.Make<int>("PauseManager", "gameManager", "internalCurrentState");
		return true;
	});

    current.totalTime = 0;
    current.realWave = 0;
}

onStart
{
    vars.ResetSplits();
    current.totalTime = 0;

	vars.Log(current.activeScene);
	vars.Log(current.wave);
	vars.Log(current.timer);
	vars.Log(current.state);
}

update
{
    vars.Watch("wave");
    vars.Watch("state");

	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

    current.realWave = current.state >= 32 ? current.realWave : current.wave;

    if (old.realWave != current.realWave) vars.Log("realWave: " + old.realWave + " -> " + current.realWave);

    if ((int) current.timer == 0 && old.timer >= 1) current.totalTime += (int) old.timer;
}

start
{
    return current.realWave == 0 && old.timer < current.timer && old.timer < 0.2;
}

split
{
    // if ()

    if (current.realWave != 0 && current.realWave == old.realWave + 1)
    {
        if (current.realWave == 4 && settings["stage"])
        {
            return vars.CheckSplit("stage_" + current.activeScene, true);
        }

        if (settings["wave"])
        {
            return vars.CheckSplit("wave_" + current.activeScene + "_" + current.wave, false);
        }
    }
}

gameTime
{
    return TimeSpan.FromSeconds(current.totalTime + (int) current.timer);
}

isLoading
{
    return true;
}