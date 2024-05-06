// autosplitter by diggity, mello, streetbackguy
state("Bendy and the Dark Revival") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Bendy and the Dark Revival";
    vars.Helper.AlertLoadless();

    vars.Helper.Settings.CreateFromXml("Components/BATDR.Settings.xml");
    /** because of the layout of the settings, some settings actually mean the same thing.
        notably, where an objective completing also completes a chapter
        we have settings for all chapters and all objectives, so this point actually appears twice
        so we provide the option for aliases
    
        the idea is that the key here is the setting that's actually checked in-code
     */
    vars.SettingAliases = new Dictionary<string, List<string>>() {
        { "csc_10201", new List<string>() { "ch_intro" } },
        { "csc_11008", new List<string>() { "ch_1" } },
        { "CHAPTER THREE:", new List<string>() { "ch_2" } },
        { "csc_11801", new List<string>() { "ch_3" } },
        { "csc_12301", new List<string>() { "ch_4" } },
        { "csp_13009", new List<string>() { "ch_5" } }
    };

    // ensures we don't double split the same condition
    vars.CompletedSplits = new Dictionary<string, bool>();
    vars.ResetSplits = (Action)(() => { foreach(var split in new List<string>(vars.CompletedSplits.Keys)) vars.CompletedSplits[split] = false; });
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var gm = mono["GameManager"];
        vars.Helper["gm"] = mono.Make<IntPtr>(gm, "m_Instance");
        vars.Helper["GameState"] = mono.Make<int>(gm, "m_Instance", "GameState");
        vars.Helper["PauseMenuActive"] = mono.Make<bool>(gm, "m_Instance", "UIManager", "m_UIGameMenu", "IsActive");
        vars.Helper["GMIsPaused"] = mono.Make<bool>(gm, "m_Instance", "IsPaused");
        vars.Helper["IsPauseReady"] = mono.Make<bool>(gm, "m_Instance", "IsPauseReady");

        vars.Helper["playerState"] = mono.Make<int>(gm, "m_Instance", "Player", "CurrentState");
        vars.Helper["ChapterTitle"] = mono.MakeString(gm, "m_Instance", "m_UIChapterTitle", 0x58, 0xC0);

        vars.Helper["cutsceneID"] = mono.Make<int>(gm, "m_Instance", "m_UICutsceneBars", "m_CutsceneDirector", "m_CutsceneID");
        vars.Helper["cutscenePlaying"] = mono.Make<bool>(gm, "m_Instance", "m_UICutsceneBars", "m_CutsceneDirector", "IsPlaying");

        // doesn't get detected by cutscene director
        var sdo = mono["SectionDataObject"];
        var cdo = mono["CutsceneDataObject"];
        vars.Helper["standUpCutsceneStatus"] = mono.Make<int>(gm, "m_Instance", "GameData", "CurrentSave", "m_DataDirectories", "m_SectionDirectory", 0x20, 0x10, 0x28, sdo["m_CutsceneData"], 0x20, 0x10, 0x80, cdo["m_Status"]);

        #region Tasks / Objectives
        // 0x20 refers to Data<Key, Value>#m_Values, i believe there is a conflict with the other Data class.
        vars.Helper["tasks"] = mono.MakeList<IntPtr>(gm, "m_Instance", "GameData", "CurrentSave", "m_DataDirectories", "m_TaskDirectory", 0x20);
        
        var tdo = mono["TaskDataObject"];
        vars.ReadTDO = (Func<IntPtr, dynamic>)(tdoP =>
        {
            dynamic ret = new ExpandoObject();
            ret.ID = vars.Helper.Read<int>(tdoP + tdo["m_DataID"]);
            ret.IsComplete = vars.Helper.Read<bool>(tdoP + tdo["m_IsComplete"]);
            return ret;
        });
        #endregion

        #region Memory
        vars.Helper["memories"] = mono.MakeList<IntPtr>(gm, "m_Instance", "GameData", "CurrentSave", "m_DataDirectories", "m_CollectableDirectory", "m_MemoryDirectory", 0x20);

        var mdo = mono["MemoryDataObject"];
        vars.ReadMDO = (Func<IntPtr, int>)(mdoP => { return vars.Helper.Read<int>(mdoP + mdo["m_DataID"]); });
        #endregion

        return true;
    });

    /** helper func to check settings */
    vars.Setting = (Func<string, bool, bool>)((key, checkCompleted) =>
    {
        // if opted into, false if the setting has already been completed
        if (checkCompleted && vars.CompletedSplits.ContainsKey(key) && vars.CompletedSplits[key]) return false;

        // true if the setting exists and is checked
        // if the setting doesn't exist check the aliases
        if (settings.ContainsKey(key) && settings[key]) return true;

        // to do with aliases - if no alias entry exists, false
        if (!vars.SettingAliases.ContainsKey(key)) return false;

        // if any of the aliases are true, then this setting is true
        foreach(var k in vars.SettingAliases[key])
        {
            if (settings[k]) return true;
        }

        // otherwise return false
        return false;
    });
}

onStart
{
    timer.IsGameTimePaused = current.IsLoading;
    vars.ResetSplits();
}

update
{
    current.IsLoadingSection = vars.Helper.Read<IntPtr>(current.gm + 0xD0) != IntPtr.Zero;
    current.IsPaused = current.PauseMenuActive && current.GameState == 4 && current.GMIsPaused && current.IsPauseReady;
    current.IsLoading = current.IsLoadingSection || (settings["remove_paused"] && current.IsPaused);
}

start
{
    // Inactive -> Active
    return old.standUpCutsceneStatus == 0 && current.standUpCutsceneStatus == 2;
}

split
{
    // Cutscenes
    if (!old.cutscenePlaying && current.cutscenePlaying && vars.Setting("csp_" + current.cutsceneID, true))
    {
        vars.Log("Cutscene Playing | " + current.cutsceneID);
        vars.CompletedSplits["csp_" + current.cutsceneID] = true;
        return true;
    }

    if (old.playerState == 1 && current.playerState == 3 && vars.Setting("csc_" + current.cutsceneID, true))
    {
        vars.Log("Cutscene Complete | " + current.cutsceneID);
        vars.CompletedSplits["csc_" + current.cutsceneID] = true;
        return true;
    }

    if (old.ChapterTitle != current.ChapterTitle && current.ChapterTitle == "CHAPTER THREE:")
    {
        vars.Log("Chapter 2 Complete | " + current.ChapterTitle);
        vars.CompletedSplits["CHAPTER THREE:"] = true;
        return true;
    }

    foreach(var task in current.tasks)
    {
        var tdo = vars.ReadTDO(task);
        string key = "obj_" + tdo.ID;

        if (vars.Setting(key, true) && tdo.IsComplete)
        {
            vars.Log("Objective Complete | " + tdo.ID);
            vars.CompletedSplits[key] = true;
            return true;
        }
    }

    foreach(var memori in current.memories)
    {
        var mdo = vars.ReadMDO(memori);
        string key = "memory_" + mdo;
        if (vars.Setting(key, true))
        {
            vars.Log("Memory collected | " + mdo);
            vars.CompletedSplits[key] = true;
            return true;
        }
    }
}

isLoading
{
    return current.IsLoading;
}
