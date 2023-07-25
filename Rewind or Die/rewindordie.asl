state("Rewind Or Die") { }

startup
{
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
        vars.Helper["bossIsDead"] = mono.Make<bool>("PigManBossFight", "instance", "isDead");
        
        var ItemData = mono["ItemData"];
        vars.Helper["items"] = mono.MakeList<IntPtr>("Inventory", "allInventoryItems");
        
        vars.ParseItem = (Func<IntPtr, dynamic>)(item =>
        {
            return vars.Helper.ReadString(item + ItemData["UUID"]);
        });

        return true;
    });

    current.apartmentWaitingForStart = false;

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
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    if (old.activeScene != current.activeScene && current.activeScene == "Apartment") {
        current.apartmentWaitingForStart = true;
    } else if (current.activeScene != "Apartment") {
        current.apartmentWaitingForStart = false;
    }

}

isLoading
{
    return current.loadingScene != current.activeScene;
}

start
{
    if (settings["ch_start"]
     && old.activeScene == "01_MainMenu" && old.activeScene != current.activeScene) {
        return true;
    }

    return current.apartmentWaitingForStart
        && !old.moving && current.moving;
}

split
{
    // Scene change
    if (old.loadingScene != current.loadingScene && current.loadingScene != "01_MainMenu")
    {
        var key = "scene_" + old.loadingScene;
        if (vars.CheckSplit(key))
            return true;
    }

    if (!old.bossIsDead && current.bossIsDead && vars.CheckSplit("boss_slaw"))
        return true;

    
    // detect new items picked up
    if (old.items.Count < current.items.Count) {
        var newItem = vars.ParseItem(current.items[current.items.Count - 1]);
        var key = "item_" + newItem;
        if (vars.CheckSplit(key))
            return true;
    }
}