state("DOOMTheDarkAges") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "DOOM: The Dark Ages";
    vars.Helper.Settings.CreateFromXml("Components/DoomTheDarkAges.Settings.xml");

    #region debugging
    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) =>
    {
        // here we see a wild typescript dev attempting C#... oh, the humanity...
        var currentValue = currentLookup.ContainsKey(key) ? currentLookup[key] : null;
        var oldValue = oldLookup.ContainsKey(key) ? oldLookup[key] : null;

        // print if there's a change
        if (oldValue != null && currentValue != null && !oldValue.Equals(currentValue)) {
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
        }

        // first iteration, print starting values
        if (oldValue == null && currentValue != null) {
            vars.Log(key + ": " + currentValue);
        }
    });

    // creates text components for variable information
	vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
	        var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
	        var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
	        if (textSetting == null)
	        {
                var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
                var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
                timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));

                textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
                textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
	        }

	        textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
    });

    settings.Add("debugging", false, "(debugging) Variable Information");
	settings.Add("Loading", false, "Current Loading", "debugging");
    settings.Add("map", false, "Current map", "debugging");
    #endregion

    vars.CompletedSplits = new HashSet<string>();
    vars.CompletedQuests = new HashSet<int>();

    vars.Helper.AlertLoadless();
}

init
{
    #region settings helpers
    // We use the last checkpoint before the end of level screen to determine what chapter we were in
    // Unfortunately, the next map gets loaded just before the EOL screen goes up, so actually the
    //  first checkpoint of the next level gets set here.
    // We don't really care about these, so we'll just ignore them when they come up, so our original
    //  method still works.
    // A bit hacky, but this is autosplitter dev for you.
    vars.StartCheckpoints = new HashSet<string> {
        "",
        "cp_01_start",
        "checkpoints_player_start_cp_01",
        "checkpoint_player_start_cp_01",
        "checkpoint_player_start_cp_01_arrival",
        "cp_01",
        "cp12_belly_start",
        "cp_05_swamp",
        "cp_04_atlan",
        "cp_08a_entrance_destroyed",
        "cp_05_ancestral"
    };

    // For the purpose of supporting multiple split criteria to a single setting
    // Changing the ID of a split unchecks it for users, so tying these together closely
    //   is pretty inconvenient.
    // criteria -> split setting
    vars.SplitMap = new Dictionary<string, string>
    {
        // https://www.youtube.com/watch?v=TmhvIv4zU0I is a debug run that i got all this from
        { "eol__cp_09_turret",                  "chapter__village" },
        { "eol__cp_08a_gore_deck_leader",       "chapter__hebeth" },
        { "eol__cp_06_armored_fight",           "chapter__core" },
        { "eol__cp_10b_vagary",                 "chapter__barracks" },
        { "eol__cp_09_surprise",                "chapter__aratum" },
        { "eol__cp_02k_pre_armory_2",           "chapter__siege_1" },
        { "eol__cp_11b_hangar_crane",           "chapter__siege_2" },
        { "eol__cp_04b_agaddon",                "chapter__forest" },
        { "eol__cp_07_final_arena",             "chapter__forge" },
        { "eol__cp_03a_get_to_atlan",           "chapter__plains" },
        { "eol__cp_06_temple_interior",         "chapter__hellbreaker" },
        { "eol__cp_07_finale_complete",         "chapter__station" },
        { "eol__cp_05a_summit_slayer_complete", "chapter__from_beyond" },
        { "eol__cp_06f_kaiju_cage_end",         "chapter__spire" },
        { "eol__cp_04a_alley_post_combat",      "chapter__city" },
        { "eol__cp_06_final_arena",             "chapter__marshes" },
        { "eol__cp_11_temple_midpoint",         "chapter__temple" },
        { "eol__cp_20_thira",                   "chapter__belly" },
        { "eol__cp_19_barge_c",                 "chapter__harbor" },
        { "eol__cp_03b_boss_phase_2",           "chapter__resurrection" },
        { "eol__cp_07c_prince_phase_3",         "chapter__final_battle" },
        { "eol__cp_08a_final_boss_phase_2",     "chapter__reckoning" }
    };

    vars.Setting = (Func<string, bool>)(key =>
    {
        return settings.ContainsKey(key) && settings[key];
    });

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(criteria =>
    {
        var key = vars.SplitMap.ContainsKey(criteria) ? vars.SplitMap[criteria] : criteria;

        // if the split doesn't exist, or it's off, or we've done it already
        if (!vars.Setting(key)
          || !vars.CompletedSplits.Add(key)
        ) {
            return false;
        }

        vars.Log("Completed: " + key);
        return true;
    });
    #endregion

    #region class inference and dumping
    char[] separators = new char[]{'"','\\','/','?',':','<', '>', '*', '|'};
    var EncodeToFileName = (Func<string, string>)(className => {
        string[] temp = className.Split(separators, StringSplitOptions.RemoveEmptyEntries);
        var name = String.Join("%", temp);

        if (name.Length > 200) {
            vars.Log("warning: truncated " + className);
            return name.Substring(0, 200);
        }

        return name;
    });

    var CLASS_SIZE = 0x58;
    var CLASS_OFFSET_NAME = 0x0;
    var CLASS_OFFSET_SUPER = 0x8;
    var CLASS_OFFSET_SIZE = 0x18;
    var CLASS_OFFSET_FIELDS = 0x28;
    var CLASS_OFFSET_PROPERTIES = 0x50;

    var FIELD_SIZE = 0x58;
    var FIELD_OFFSET_TYPE = 0x0;
    var FIELD_OFFSET_NAME = 0x10;
    var FIELD_OFFSET_OFFSET = 0x18;
    var FIELD_OFFSET_SIZE = 0x1C;
    var FIELD_OFFSET_DESCRIPTION = 0x30;

    string docPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);

    var DumpClass = (Func<IntPtr, int, int>)((classPtr, classIdx) => {
        var className = vars.Helper.ReadString(512, ReadStringType.UTF8, classPtr + CLASS_OFFSET_NAME, 0x0);
        var classSuperName = vars.Helper.ReadString(512, ReadStringType.UTF8, classPtr + CLASS_OFFSET_SUPER, 0x0);
        var classSize = vars.Helper.Read<int>(classPtr + CLASS_OFFSET_SIZE);

        var classDef = "class " + className;
        if (classSuperName != null && classSuperName != "") {
            classDef += " : " + classSuperName;
        }


        List<string> lines = new List<string> {
            "/** Type Info for '" + className + "'",
            " * ",
        };

        var properties = vars.Helper.ReadString(512, ReadStringType.UTF8, classPtr + CLASS_OFFSET_PROPERTIES, 0x0, 0x0);
        if (properties != null) {
            lines.AddRange(new List<string> {
                " * 'properties'?: " + properties,
                " *",
            });
        }

        lines.AddRange(new List<string> {
            " * At the time of dump (these will not mean anything for you):",
            " * - address: 0x" + classPtr.ToString("X"),
            " * - index: " + classIdx,
            " */",
            "",
            "// size: 0x" + classSize.ToString("X"),
            classDef + " {",
        });


        var currentFieldPtr = vars.Helper.Read<IntPtr>(classPtr + CLASS_OFFSET_FIELDS);

        while (true) {
            var name = vars.Helper.ReadString(512, ReadStringType.UTF8, currentFieldPtr + FIELD_OFFSET_NAME, 0x0);
            if (name == "" || name == null) {
                break;
            }
            var type = vars.Helper.ReadString(512, ReadStringType.UTF8, currentFieldPtr + FIELD_OFFSET_TYPE, 0x0);
            var offset = vars.Helper.Read<int>(currentFieldPtr + FIELD_OFFSET_OFFSET);
            var size = vars.Helper.Read<int>(currentFieldPtr + FIELD_OFFSET_SIZE);
            var desc = vars.Helper.ReadString(512, ReadStringType.UTF8, currentFieldPtr + FIELD_OFFSET_DESCRIPTION, 0x0);

            var fieldInfo = ("    " + type + " " + name + ";").PadRight(120);
            var offsetStr = "0x" + offset.ToString("X").PadLeft(5, '0');
            lines.Add(fieldInfo + "// " + offsetStr + " (size: 0x" + size.ToString("X") + ") - " + desc);

            currentFieldPtr += FIELD_SIZE;
        }

        lines.Add("}");

        File.WriteAllLines(Path.Combine(docPath, "DTDA typeinfo", EncodeToFileName(className) + ".cpp"), lines);

        return 0;
    });

    vars.DumpAllClasses = (Action)(() =>
    {
        Directory.CreateDirectory(Path.Combine(docPath, "DTDA typeinfo"));

        // quick note to find this: search for a class name in static unwritable,
        //  find usages of that address, should be one in an array, scroll to the beginning of the array
        //  search for that
        //  something like that
        // TODO: i should probably make a sig for this
        var classArray = (IntPtr) 0x147F49118;
        var classArraySize = (IntPtr) 0x147F49120;

        var classArrayS = vars.Helper.Read<int>(classArraySize);
        var currentClass = vars.Helper.Read<IntPtr>(classArray);
        for (var i = 0; i < classArrayS; i++) {
            try {
                vars.ReadClassThing(currentClass, i);
            } catch (Exception e) {
                vars.Log(e);
            }

            currentClass += CLASS_SIZE;
        }
    });

    #endregion

    // the root of all evil
    vars.idGameSystemLocal = vars.Helper.ScanRel(0x6, "FF 50 40 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0");
    vars.Log("Found idGameSystemLocal at 0x" + vars.idGameSystemLocal.ToString("X"));

    // enum idGameSystemLocal::state_t {
    //   GAME_STATE_MAIN_MENU = 0,
    //   GAME_STATE_LOADING = 1,
    //   GAME_STATE_INGAME = 2,
    // }
    vars.Helper["gameState"] = vars.Helper.Make<int>(
        vars.idGameSystemLocal + 0x40 // idGameSystemLocal::state_t state
    );
    vars.Helper["map"] = vars.Helper.MakeString(
        vars.idGameSystemLocal + 0x48, // idMapInstance mapInstance
        0x20, // idStrStatic < 1024 > mapName (does not show up in dumps)
        0x0
    );
    vars.Helper["checkpoint"] = vars.Helper.MakeString(
        vars.idGameSystemLocal + 0x48, // idMapInstance mapInstance
        0x1060, // idStrStatic < 1024 > checkpointName (does not show up in dumps)
        0x0
    );

    #region Menus
    // the idPlayer was pointer scanned for, and walked back - we don't have type information for idMapInstance, nor whatever the class is at 0x1988
    vars.Helper["hudMenus"] = vars.Helper.Make<IntPtr>(
        vars.idGameSystemLocal + 0x48, // idMapInstance mapInstance
        0x1988, // ??
        0xC0, // an idPlayer
        0x2EA18 // idHUD playerHud
        + 0x368 // idList < idMenu* > menus
    );
    vars.Helper["hudMenusSize"] = vars.Helper.Make<int>(
        vars.idGameSystemLocal + 0x48, // idMapInstance mapInstance
        0x1988, // ??
        0xC0, // an idPlayer
        0x2EA18 // idHUD playerHud
        + 0x370 // idList < idMenu* > menus
    );

    vars.GetActiveScreens = (Func<HashSet<string>>)(() => {
        var ret = new HashSet<string>();

        // I have a hunch that it's always at i=2, but do our due diligence...
        for (var i = 0; i < current.hudMenusSize; i++) {
            var currentScreen = vars.Helper.ReadString(
                512, ReadStringType.UTF8,
                current.hudMenus + i * 0x8,
                0x68 // idMenu::menuScreenId_t currentScreen
                + 0x8, // idAtomicString titanId
                0x0
            );
            ret.Add(currentScreen);
        }

        return ret;
    });

    vars.IsInEndOfLevelScreen = (Func<bool>)(() => {
        var screens = vars.GetActiveScreens();
        return screens.Contains("mission_complete") || screens.Contains("end_of_level");
    });
    #endregion

    #region Quests
    vars.Helper["quests"] = vars.Helper.Make<IntPtr>(
        vars.idGameSystemLocal + 0x1A30, // idQuestSystem questSystem
        0x0 // idList<idQuest*> quests
        + 0x0 // idQuest* list
    );
    vars.Helper["questsSize"] = vars.Helper.Make<int>(
        vars.idGameSystemLocal + 0x1A30, // idQuestSystem questSystem
        0x0 // idList<idQuest*> quests
        + 0x8 // int num
    );

    var QUEST_SIZE = 0xB8;

    // Big assumption here, in that the quests will always be in the same order and in the same positions
    //   This is at least true when comparing Meta and my quest lists, but it could break in the future
    //   I do this to save scanning the whole list, there are ~650 elements.
    // TODO: An improvement could be to assume it doesn't change once loaded, so scan it once on init and
    //   cache that list.
    //
    // enum idQuestStatus {
    //     QUEST_STATUS_LOCKED_AND_HIDDEN = 0
    //     QUEST_STATUS_LOCKED = 1
    //     QUEST_STATUS_UNLOCKED = 2
    //     QUEST_STATUS_IN_PROGRESS = 3
    //     QUEST_STATUS_COMPLETE = 4
    //     QUEST_STATUS_FAILED = 5
    // }
    vars.ReadQuestStatus = (Func<int, int>)(questIdx =>
    {
        return vars.Helper.Read<int>(
            current.quests + questIdx * QUEST_SIZE // [questIdx]
             + 0x8 // idQuestStatus questStatus
        );
    });
    vars.ReadQuestName = (Func<int, string>)(questIdx =>
    {
        return vars.Helper.ReadString(
            512, ReadStringType.UTF8,
            current.quests + questIdx * QUEST_SIZE // [questIdx]
             + 0x0, // idDeclQuestDef questDef
            0x88, // idStr questId
            0x0
        );
    });

    vars.LogAllQuests = (Action)(() =>
    {
        // var start = DateTime.Now;
        for (var i = 0; i < current.questsSize; i++) {

            var questStatus = vars.ReadQuestStatus(i);
            // if (questStatus == 4) {
                var questName = vars.ReadQuestName(i);

                vars.Log("quest " + i + " " + questName + " is in status " + questStatus + " (0x" + (current.quests + i * QUEST_SIZE).ToString("X") + ")");
            // }

        }
        // vars.Log(elapsed);
    });
    #endregion
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    current.isInEndOfLevelScreen = vars.IsInEndOfLevelScreen();
    // typescript dev attempts C#, fails miserably (part 2)
    current.lastActiveCheckpoint = current.checkpoint == null || vars.StartCheckpoints.Contains(current.checkpoint)
        ? ((IDictionary<string, object>) current).ContainsKey("lastActiveCheckpoint")
            ? current.lastActiveCheckpoint
            : "no checkpoint"
        : current.checkpoint;
    // map value that changes at a more favourable point
    current.activeMap = current.gameState == 1
        ? ((IDictionary<string, object>) current).ContainsKey("activeMap")
            ? current.activeMap
            : "no map"
        : current.map;

    vars.Watch(old, current, "gameState");
    vars.Watch(old, current, "map");
    vars.Watch(old, current, "activeMap");
    vars.Watch(old, current, "checkpoint");
    vars.Watch(old, current, "lastActiveCheckpoint");
    vars.Watch(old, current, "isInEndOfLevelScreen");

    if(settings["Loading"])
    {
        vars.SetTextComponent("GameState:",current.gameState.ToString());
    }

    if(settings["map"])
    {
        vars.SetTextComponent(" ",current.map.ToString());
    }
}

onStart
{
    timer.IsGameTimePaused = true;

    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
    vars.CompletedQuests.Clear();

    vars.LogAllQuests();
    // vars.DumpAllClasses();
}

isLoading
{
    return current.gameState == 1 || current.isInEndOfLevelScreen;
}

start
{
    // menu -> village of khalim, starts *after* the load now
    return old.activeMap == "game/shell/shell" && current.activeMap == "game/sp/m1_intro/m1_intro";
}

split
{

    if (vars.Setting("quests")) {
        for (var i = 0; i < current.questsSize; i++)
        {
            if (!vars.Setting("quest_" + i)) {
                continue;
            }

            if (vars.CompletedQuests.Contains(i)) {
                continue;
            }

            var questStatus = vars.ReadQuestStatus(i);
            if (questStatus != 4) {
                continue;
            }

            vars.CompletedQuests.Add(i);
            var name = vars.ReadQuestName(i);
            vars.Log("Quest completed " + i + " (" + name + ")");

            return true;
        }
    }

    // if we've just entered an end of level screen... that means we just completed a chapter
    if (!old.isInEndOfLevelScreen && current.isInEndOfLevelScreen) {
        vars.Log("entered end of level screen from checkpoint " + current.lastActiveCheckpoint);
        return vars.CheckSplit("eol__" + current.lastActiveCheckpoint);
    }

    return false;
}
