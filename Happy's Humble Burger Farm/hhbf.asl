state("Happy's Humble Burger Farm") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "HHBF";
    vars.Helper.StartFileLogger("HHBF.log");
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    vars.Scenes = new Dictionary<string, string>() {
        { "MuseumInterior", "Museum" },
        { "ParkingGarage", "Parking Garage (Museum Basement)" },
        { "OoB 3", "Charlie's Room" },
        { "Break_Room", "Break Room (Sewer)" },
    };

    settings.Add("split_scene", true, "Split on entering location:");
    foreach (var scene in vars.Scenes.Keys)
    {
        settings.Add(scene, false, vars.Scenes[scene], "split_scene");
    }

    #region EndlessSetup
    settings.Add("endless", false, "Endless% Splits");
    vars.EndlessSplits = new Dictionary<string, string>() {
        { "split_el_farm_open", "Split on opening the farm." },
        { "split_el_diner_open", "Split on opening the diner." },
        { "split_el_100", "Split on making $100." },
        { "split_el_200", "Split on making $200." },
        { "split_el_300", "Split on making $300." },
        { "split_el_400", "Split on making $400." },
    };

    foreach (var split in vars.EndlessSplits.Keys)
    {
        settings.Add(split, false, vars.EndlessSplits[split], "endless");
    }

    #endregion 

    vars.CompletedSplits = new Dictionary<string, bool>();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var pm = mono["progressManager"];
        vars.Helper["day"] = mono.Make<int>(pm, "instance", "currentDay");
        vars.Helper["lastScene"] = mono.MakeString(pm, "instance", "lastScene");
        vars.Helper["currentScene"] = mono.MakeString(pm, "instance", "currentScene");

        return true;
    });

    current.loadingScene = "";
    current.activeScene = "";
}

onStart
{
    vars.Log("TIMER STARTED");
    foreach (var scene in vars.Scenes.Keys)
    {
        vars.CompletedSplits[scene] = false;
    }

    foreach (var split in vars.EndlessSplits.Keys)
    {
        vars.CompletedSplits[split] = false;
    }

    vars.Log(current.activeScene);  // Apartment
    vars.Log(current.loadingScene); // 
    vars.Log(current.currentScene); // Apartment
    vars.Log(current.lastScene);    // Dream
    vars.Log(current.day);          // 0
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    current.isLoading = (current.lastScene == current.currentScene && current.currentScene != "Main Menu")
        || current.loadingScene != current.activeScene;
    
    if (current.isLoading && !old.isLoading) vars.Log("Starting load...");
    if (!current.isLoading && old.isLoading) vars.Log("Ending load...");

    if(current.activeScene != old.activeScene) vars.Log("SceneManager.activeScene: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
    if(current.loadingScene != old.loadingScene) vars.Log("SceneManager.loadingScene: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

    if(current.day != old.day) vars.Log("day " + current.day);
    if(current.lastScene != old.lastScene) vars.Log("progressManager.lastScene " + current.lastScene);
    if(current.currentScene != old.currentScene) vars.Log("progressManager.currentScene " + current.currentScene);
}

start
{
    // Starting on loading into Apartment
    return old.activeScene != current.activeScene
        && (old.activeScene == "Main Menu" || old.activeScene == "First Dream Tutorial")
        && current.activeScene == "Apartment" && current.day == 0;

    // Start on putting the manual away
    // return old.manualUsable && !current.manualUsable
    //     && current.activeScene == "Apartment";
}

isLoading
{
    return current.isLoading;
}

split
{

    if (old.loadingScene != current.loadingScene
        && settings.ContainsKey(current.loadingScene)
        && settings[current.loadingScene]
        && !vars.CompletedSplits[current.loadingScene])
    {
        vars.CompletedSplits[current.loadingScene] = true;
        vars.Log("Completed split " + current.loadingScene + "!");
        return true;
    }        
}