state("Rewind Or Die") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Rewind or Die";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	vars.Helper.Settings.CreateFromXml("Components/RewindOrDie.Settings.xml");
    vars.CompletedSplits = new Dictionary<string, bool>();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
        vars.Helper["moving"] = mono.Make<bool>("FPS", "instance", "moving");
		return true;
	});

    current.apartmentWaitingForStart = false;

    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off, or we've done it
        if (!settings.ContainsKey(key)) {
            vars.Log("SETTING DOESNT EXIST " + key);
            return false;
        }
        
        if (!settings[key]) {
            vars.Log("SETTING NOT ENABLED " + key);
            return false;
        }
        
        if (vars.CompletedSplits.ContainsKey(key) && vars.CompletedSplits[key]) {
            vars.Log("SPLIT COMPLETED " + key);
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
    vars.Log(current.apartmentWaitingForStart);
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    if (old.activeScene != current.activeScene && current.activeScene == "Apartment") {
        current.apartmentWaitingForStart = true;
    } else if (current.activeScene != "Apartment") {
        current.apartmentWaitingForStart = false;    }

	if(current.activeScene != old.activeScene) {
        vars.Log("ACTIVE FROM \"" + old.activeScene + "\" TO \"" + current.activeScene + "\"");
    }
	
    if(current.loadingScene != old.loadingScene)
        vars.Log("LOADING FROM \"" + old.loadingScene + "\" TO \"" + current.loadingScene + "\"");

    
    
}

isLoading
{
    return current.loadingScene != current.activeScene;
}

start
{
    return current.apartmentWaitingForStart
        && !old.moving && current.moving;
}

split
{
    // Scene change
    if (old.loadingScene != current.loadingScene && current.loadingScene != "01_MainMenu")
    {
        var key = "scene_" + old.loadingScene;
        if (vars.CheckSplit(key)) {
            return true;
        }
    }
}