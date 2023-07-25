state("Don't Be Afraid") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Don't Be Afraid";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    settings.Add("start_after_cutscene", false, "Start after the first cutscene.");

    settings.Add("split_scene", true, "Split on completing scene");

    var SceneLabels = new Dictionary<string, string>() {
        { "Basement", "Basement 1" },
        { "Basement 2", "Basement 2" },
        { "David'sHouseMOTHERENDING", "David's House 1" },
        { "Parter (01)", "Ground Floor" },
        { "FirstFloor (01)", "First Floor" },
        { "SecondFloor1", "Second Floor" },
        { "David'sHouseRETRO_DEATH", "David's House 2 (Eternal Sleep)" },
        { "David'sHouseRETRO_MOTHER", "David's House 2 (Mama's Boy)" },
        { "ThirdFloorMother&Death", "Third Floor" },
        { "Attic_Death", "Attic (Eternal Sleep)" },
        { "Attic_Mother", "Attic (Mama's Boy)" },
        { "Forest_Death", "Forest (Eternal Sleep)" },
        { "Forest_Mother", "Forest (Mama's Boy)" },
        { "ClownHouse", "Clown House 1" },
        { "ClownHouse2", "Clown House 2" }

        // BasementEnding ?
        // SchoolEnding1Mother
    };

    foreach(var scene in SceneLabels.Keys)
    {
        settings.Add(scene, false, SceneLabels[scene], "split_scene");
    }

}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;
    
    if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene);
    if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene);
}

isLoading
{
    return current.activeScene != current.loadingScene;
}

start
{
    return (!settings["start_after_cutscene"]
        && old.activeScene == "MainMenu ENG"
        && current.activeScene == "Cutscene1Basement")
        || (settings["start_after_cutscene"]
        && old.activeScene == "Cutscene1Basement"
        && current.activeScene == "Basement");
}

split
{
    return old.loadingScene != current.loadingScene
        && current.loadingScene != "MainMenu ENG"
        && current.loadingScene != "Cutscene1Basement"
        && settings.ContainsKey(old.loadingScene) && settings[old.loadingScene];
}