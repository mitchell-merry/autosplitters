state("The Last Faith") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "The Last Faith";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.Settings.CreateFromXml("Components/TheLastFaith.Settings.xml");

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (oldValue != null && currentValue != null && !oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });

    vars.CompletedSplits = new HashSet<string>();
    
    vars.Helper.AlertRealTime();
}

/* Todo
* - find a thing to measure the start point
* - get something for when boss fights start
* - picking up items (weapons, key items, etc)
*/
init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // I don't know why this is needed. asl-help reads all offsets as 0x10 earlier than they
        //   actually are. (huge pain to figure out why this wasn't working)
        var OFFSET = 0x10;
        // var UIPlayerController = mono["UIPlayerController"];
        // var UiManager = mono["UiManager"];
        // var UIPanel = mono["UIPanel"];

        // vars.Helper["hudStatus"] = UIPlayerController.Make<bool>("Instance", UIPlayerController["uiManager"] + 0x10, UiManager["currentTopHudStatus"] + 0x10);
        // vars.Helper["hud"] = UIPlayerController.Make<int>("Instance", UIPlayerController["uiManager"] + 0x10, UiManager["hud"] + 0x10, UIPanel["priority"] + 0x10);
        // vars.Helper["blackScreen"] = UIPlayerController.Make<int>("Instance", UIPlayerController["blackScreen"] + 0x10);
        // vars.Helper["showUIPC"] = UIPlayerController.Make<bool>("Show");

        // var BaseController2D = mono["BaseController2D"];
        // var BaseHealth2D = mono["BaseHealth2D"];
        // vars.Helper["healthActive"] = BaseController2D.Make<bool>("Instance", BaseController2D["Health"] + 0x10, BaseHealth2D["HealthPrefab"] + 0x10, 0x57);
        // vars.Log("HA " + vars.Helper["healthActive"]);

        var UIPlayerController = mono["UIPlayerController"];
        var DeveloperBossControllerConsole = mono["DeveloperBossControllerConsole"];
        var BossFightController = mono["BossFightController"];
        var BaseBossController = mono["BaseBossController"];
        var EnemyHealth = mono["EnemyHealth"];

        vars.Helper["boss"] = UIPlayerController.Make<int>(
            "Instance",
            UIPlayerController["bossConsole"] + OFFSET,
            DeveloperBossControllerConsole["fightControllerScript"] + OFFSET,
            BossFightController["bossName"] + OFFSET
        );

        vars.Helper["bossIsDead"] = UIPlayerController.Make<bool>(
            "Instance",
            UIPlayerController["bossConsole"] + OFFSET,
            DeveloperBossControllerConsole["fightControllerScript"] + OFFSET,
            BossFightController["Boss"] + OFFSET,
            BaseBossController["enemyHealth"] + OFFSET,
            EnemyHealth["isDead"] + OFFSET
        );
        // Other fun paths
        // 0x24
        // 0x40, 0x420, 0x21A // Boss, enemyHealth, isDead
        // 0x40, 0x420, 0x28, 0x2c // Boss, enemyHealth, health, value
        // 0x2F8 fightStarted

        // (working)
        var CurrentActiveCheckPoint = mono["CurrentActiveCheckPoint"];
        var CheckPoint = mono["CheckPoint"];
        var PersistentObject = mono["PersistentObject"];
        var PersistentObjectPath = mono["PersistentObjectPath"];
        
        vars.Helper["checkpoint"] = CurrentActiveCheckPoint.MakeString(
            "checkPoint",
            CheckPoint["persistentObject"] + OFFSET, // 0xC8
            PersistentObject["path"] + OFFSET, // 0x18,
            PersistentObjectPath["path"] + OFFSET // 0x10
        );

        vars.Helper["checkpointInMenu"] = CurrentActiveCheckPoint.Make<bool>(
            "checkPoint",
            CheckPoint["inMenu"] + OFFSET // 0xD0
        );

        return true;
    });

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
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
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    vars.Watch(old, current, "activeScene");
    vars.Watch(old, current, "loadingScene");
    if (old.checkpoint != current.checkpoint) {
        vars.Log("checkpoint: " + old.checkpoint + " -> " + current.checkpoint);
        // vars.Log("<Setting Id=\"cp_" + current.checkpoint + "\" Label=\"\" State=\"false\">");
    }
     vars.Watch(old, current, "checkpointInMenu");

     vars.Watch(old, current, "boss");
     vars.Watch(old, current, "bossIsDead");

    // vars.Watch(old, current, "showUIPC");
    // vars.Watch(old, current, "healthActive");

    // vars.Watch(old, current, "boss");
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log(current.activeScene);
    vars.Log(current.checkpoint);
    vars.Log(current.checkpointInMenu);

    vars.Log(current.boss);
    vars.Log(current.bossIsDead);
    // vars.Log(current.hudStatus);
    // vars.Log(current.hud);
    // vars.Log(current.healthActive);
}

isLoading
{
    return current.loadingScene != current.activeScene;
}

split
{
    if (settings["checkpoint"]
     && !old.checkpointInMenu && current.checkpointInMenu
     && vars.CheckSplit(current.checkpoint)
    ) {
        return true;
    }

    
    if (settings["boss_death"]
     && !old.bossIsDead && current.bossIsDead
     && vars.CheckSplit("boss_" + current.boss)
    ) {
        return true;
    }
}