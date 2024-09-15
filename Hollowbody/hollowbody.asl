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
        
        vars.Helper["isLoading"] = KickStarter.Make<bool>("sceneChangerComponent",  SceneChanger["isLoading"]);
        vars.Helper["menus"] = KickStarter.MakeList<IntPtr>("playerMenusComponent", PlayerMenus["menus"]);

        var Menu = mono["Menu"];
        var MenuLabel = mono["MenuLabel"];
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
                    var elementS = vars.Helper.ReadString(element + MenuLabel["title"]);
                    
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
    current.isCallQuestionActive = settings["split--call"]
        && current.activeScene == "Nest_Sasha"
        && vars.IsQuestionActive(current.menus, "Answer the call?");

    vars.Watch(old, current, "activeScene");
    vars.Watch(old, current, "loadingScene");
    vars.Watch(old, current, "isLoading");
    vars.Watch(old, current, "isCallQuestionActive");
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log(current.activeScene);
    vars.Log(current.isLoading);
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