state("Hollowbody") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Hollowbody";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.Settings.CreateFromXml("Components/Hollowbody.Settings.xml");

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });

    vars.CompletedSplits = new HashSet<string>();
    
    vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var KickStarter = mono["KickStarter"];
        var SceneChanger = mono["SceneChanger"];
        var PlayerMenus = mono["PlayerMenus"];
        var Menu = mono["Menu"];
        var MenuElement = mono["MenuElement"];
        var MenuLabel = mono["MenuLabel"];
        
        vars.Helper["isLoading"] = KickStarter.Make<bool>("sceneChangerComponent",  SceneChanger["isLoading"]);
        vars.Helper["menus"] = KickStarter.MakeList<IntPtr>("playerMenusComponent", PlayerMenus["menus"]);

        // var Speech = mono["Speech"];
        // var SpeechLog = mono["SpeechLog"];
        // vars.Helper["speechList"] = mono.MakeList<IntPtr>("KickStarter", "dialogComponent", "speechList");

        // vars.ReadSpeech = (Func<IntPtr, string>)(speech =>
        // {
        //     return vars.Helper.ReadString(speech + Speech["originalText"]);//, SpeechLog["textWithRichTextTags"]);
        // });

        // vars.ReadSpeechList = (Func<List<IntPtr>, List<string>>)(speechList =>
        // {
        //     var ret = new List<string>();

        //     foreach(var speechPtr in speechList) {
        //         ret.Add(vars.ReadSpeech(speechPtr));
        //     }

        //     return ret;
        // });

        vars.IsQuestionActive = (Func<List<IntPtr>, string, bool>)((menus, question) =>
        {
            foreach (var menu in menus)
            {
                var enabled = vars.Helper.Read<bool>(menu + Menu["isEnabled"]);
                if (!enabled)
                {
                    continue;
                }
                
                var s = vars.Helper.ReadString(menu + Menu["title"]);
                if (s != "YesNo")
                {
                    continue;
                }

                var elements = vars.Helper.ReadList<IntPtr>(menu + Menu["elements"]);
                foreach (var element in elements)
                {
                    var elementS = vars.Helper.ReadString(element + MenuElement["title"]);
                    
                    if (elementS == "YesNoText")
                    {
                        var label = vars.Helper.ReadString(element + MenuLabel["newLabel"]);
                        return label == question;
                    }
                }
            }

            return false;
        });

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
    // current.isCallQuestionActive = vars.IsQuestionActive(current.menus, "Take the <b>Detonator</b>?");
    current.isCallQuestionActive = settings["split--call"]
        && current.activeScene == "Nest_Sasha"
        && vars.IsQuestionActive(current.menus, "Answer the call?");

    // HeadwareSplash, ViolenceWarning, TitleMenu
    // Death

    // IntroNarration
    // Cliffs_Fog
    // Cave
    // CityApartment
    // City_FlyOver
    // TownCrash
    // Block_Int_Part1
    // SushiFlashback
    // Block_Int_Part2
    // Park
    // House_Watcher
    // House_Victim
    // Church
    // BarFlashback
    // Sewers
    // Highstreet_Part1
    // Highstreet_Part2
    // ApologyFlashback
    // Underground
    // Nest
    // Nest_Sasha
    // Tunnels_Ending

    vars.Watch(old, current, "activeScene");
    vars.Watch(old, current, "loadingScene");
    vars.Watch(old, current, "isLoading");
    vars.Watch(old, current, "isCallQuestionActive");

    // if (old.speechList.Count != current.speechList.Count) {
    //     vars.Log(current.speechList.Count);
    //     var speechList = vars.ReadSpeechList(current.speechList);
    //     foreach(var speech in speechList) {
    //         vars.Log(speech);
    //     }
    // }

    // if (old.m.Count != current.menus.Count)
    // {
    //     vars.Log("menu count: " + current.menus.Count);
    // }
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log(current.activeScene);
    vars.Log(current.isLoading);
    // vars.Log(current.loadingProgress);
    // vars.Log(current.loadingDelay);

    // var speechList = vars.ReadSpeechList(current.speechList);
    // foreach(var speech in speechList) {
    //     vars.Log(speech);
    // }
}

onSplit
{
    
    // vars.Log(current.isCallQuestionActive);
    // vars.Log(current.speechList.Count);
    // var speechList = vars.ReadSpeechList(current.speechList);
    // foreach(var speech in speechList) {
    //     vars.Log(speech);
    // }

    // vars.Log(current.menus.Count);
    // foreach(var mi in current.menus) {
    //     vars.DebugMenu(mi);
    //     // vars.Log(vars.ReadMenu);
    // }
}

isLoading
{
    return current.isLoading;
}

start
{
    return old.activeScene == "TitleMenu" && current.activeScene == "IntroNarration";
}

split
{
    if (settings["split--scene"] && old.loadingScene != current.loadingScene)
    {
        var setting = "scene--" + old.loadingScene + "--" + current.loadingScene;
        if (vars.CheckSplit(setting))
        {
            return true;
        }
    }

    return old.isCallQuestionActive && !current.isCallQuestionActive;
}