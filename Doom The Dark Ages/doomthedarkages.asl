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
        var currentValue = currentLookup.ContainsKey(key) ? (currentLookup[key] ?? "(null)") : null;
        var oldValue = oldLookup.ContainsKey(key) ? (oldLookup[key] ?? "(null)") : null;

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

    // For the purpose of supporting multiple split criteria to a single setting
    // Changing the ID of a split unchecks it for users, so tying these together closely
    //   is pretty inconvenient.
    // criteria -> split setting
    vars.SplitMap = new Dictionary<string, string>
    {
        { "eol__maps/game/sp/m1_intro_name",             "chapter__village" },
        { "eol__maps/game/sp/m2_hebeth_name",            "chapter__hebeth" },
        { "eol__maps/game/sp/m2b_hebeth_atlan_name",     "chapter__core" },
        { "eol__maps/game/sp/m3_holy_city_name",         "chapter__barracks" },
        { "eol__maps/game/sp/m3b_holy_city_dragon_name", "chapter__aratum" },
        { "eol__maps/game/sp/m4_siege_name",             "chapter__siege_1" },
        { "eol__maps/game/sp/m4b_siege_return_name",     "chapter__siege_2" },
        { "eol__maps/game/sp/m5_forge_name",             "chapter__forest" },
        { "eol__maps/game/sp/m5b_forge_heart_name",      "chapter__forge" },
        { "eol__maps/game/sp/m6_hell_name",              "chapter__plains" },
        { "eol__maps/game/sp/m6b_hell_atlan_name",       "chapter__hellbreaker" },
        { "eol__maps/game/sp/m7_armada_name",            "chapter__station" },
        { "eol__maps/game/sp/m7b_armada_dragon_name",    "chapter__from_beyond" },
        { "eol__maps/game/sp/m8_terror_name",            "chapter__spire" },
        { "eol__maps/game/sp/m9_cosmic_a_name",          "chapter__city" },
        { "eol__maps/game/sp/m9b_cosmic_a_name",         "chapter__marshes" },
        { "eol__maps/game/sp/m10_cosmic_b_name",         "chapter__temple" },
        { "eol__maps/game/sp/m10b_cosmic_b_beast_name",  "chapter__belly" },
        { "eol__maps/game/sp/m11_styx_name",             "chapter__harbor" },
        { "eol__maps/game/sp/m12_argent_ret_name",       "chapter__resurrection" },
        { "eol__maps/game/sp/m13_final_battle_name",     "chapter__final_battle" },
        { "eol__maps/game/sp/m14_hell_boss_name",        "chapter__reckoning" },

        // Quests
        { "quests_134_0", "quests_cte_rv" },
        { "quests_134_1", "quests_cte_cv" },
        { "quests_134_2", "quests_cte_fk" },
        { "quests_134_3", "quests_cte_og" },
        { "quests_134_4", "quests_cte_dp" },
        { "quests_134_4_progress", "quests_cte_dp_progress" },
        { "quests_134_5", "quests_cte_db" },
    };

    // quest idx -> (quest step idx -> progress at "completion")
    vars.QuestsToCheck = new Dictionary<int, Dictionary<int, int>> {
        {
            134, // m1_intro_objective_cover_escape
            new Dictionary<int, int> {
                { 0, 1 },
                { 1, 1 },
                { 2, 1 },
                { 3, 1 },
                { 4, 4 },
                { 5, 1 }
            }
        }
    };

    vars.CompletedSplits = new HashSet<string>();
    vars.CompletedQuests = new HashSet<int>();

    vars.Helper.AlertLoadless();
}

init
{
    #region settings helpers

    vars.Setting = (Func<string, bool>)(criteria =>
    {
        var key = vars.SplitMap.ContainsKey(criteria)
            ? vars.SplitMap[criteria]
            : criteria;

        return settings.ContainsKey(key) && settings[key];
    });

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, string, bool>)((criteria, setting) =>
    {
        var key = setting != ""
            ? setting
            : vars.SplitMap.ContainsKey(criteria)
                ? vars.SplitMap[criteria]
                : criteria;

        // if the split doesn't exist, or it's off, or we've done it already
        if (!vars.Setting(key)
          || !vars.CompletedSplits.Add(criteria)
        ) {
            return false;
        }

        vars.Log("Completed: " + criteria);
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

    // only defined when we're in the end of level screen
    vars.Helper["eolChapterName"] = vars.Helper.MakeString(
        vars.idGameSystemLocal
         + 0x48, // idMapInstance mapInstance
        0x1988,  // ??
        0xC0,    // an idPlayer
        0x2EA18  // idHUD playerHud
        + 0x368, // idList < idMenu* > menus
        0x8 * 2, // [2] ("playermenu")
        0x20     // idListMap < idAtomicString , idMenuElement * > screens
        + 0x18,  // idList < idMenuElement * > sortedValueList
        0x8 * 2, // [2] ("playermenu/eol_mission_complete")
        0xA8     // idSharedPtr < idUIWidget > rootWidgetNew (idUIWidget "ui/screens")
        + 0x0,   // idSharedPtrData data
        0x8,     // interlockedPointer_t < void > pointer
        0x70     // idSharedPtr < idUIWidgetModelInterface > modelInterface
        + 0x0,   // idSharedPtrData data
        0x8,     // interlockedPointer_t < void > pointer
        0x190    // idSharedPtr < idUIWidgetModel > model (idUIWidgetModel_EOL_Mission_Complete)
        + 0x0,   // idSharedPtrData data
        0x8,     // interlockedPointer_t < void > pointer
        0x38,    // idDeclString chapterName
        0x8,     // decl name or key ? look like "maps/game/sp/m6_hell_name"
        0x0
    );
    vars.Helper["eolChapterName"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

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
    var QUEST_STEP_SIZE = 0x70;

    // Big assumption here, in that the quests will always be in the same order and in the same positions
    //   This is at least true when comparing Meta and my quest lists, but it could break in the future
    //   I do this to save scanning the whole list, there are ~650 elements.
    // TODO: An improvement could be to assume it doesn't change once loaded, so scan it once on init and
    //   cache that list.

    vars.ReadQuestStepProgress = (Func<int, int, int>)((questIdx, stepIdx) =>
    {
        return vars.Helper.Read<int>(
            current.quests + questIdx * QUEST_SIZE // [questIdx]
             + 0x10, // idList < idQuestStep > questSteps
             stepIdx * QUEST_STEP_SIZE // [questStepIdx]
             + 0x30 // idQuestRequirementProgress progress
             + 0x0 // unsigned int trackedValue
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
    // map value that changes at a more favourable point
    current.activeMap = current.gameState == 1
        ? ((IDictionary<string, object>) current).ContainsKey("activeMap")
            ? current.activeMap
            : "no map"
        : current.map;

    vars.Watch(old, current, "gameState");
    vars.Watch(old, current, "map");
    vars.Watch(old, current, "activeMap");
    vars.Watch(old, current, "isInEndOfLevelScreen");
    vars.Watch(old, current, "eolChapterName");

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
    vars.Log("timer started");
    timer.IsGameTimePaused = true;

    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
    vars.CompletedQuests.Clear();

    // vars.LogAllQuests();
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
        foreach(KeyValuePair<int, Dictionary<int, int>> questEntry in vars.QuestsToCheck)
        {
            foreach(KeyValuePair<int, int> questStepEntry in questEntry.Value)
            {
                var settingKey = "quests_" + questEntry.Key + "_" + questStepEntry.Key;
                if (!vars.Setting(settingKey))
                {
                    continue;
                }

                var progress = vars.ReadQuestStepProgress(questEntry.Key, questStepEntry.Key);
                if (progress == 0)
                {
                    continue;
                }

                if (progress == questStepEntry.Value)
                {
                    if (vars.CheckSplit(settingKey, ""))
                    {
                        return true;
                    }
                } else {
                    if (vars.CheckSplit(settingKey + "_" + progress, settingKey + "_progress"))
                    {
                        vars.Log("progress: " + progress);
                        return true;
                    }
                }
            }
        }
    }

    if (old.eolChapterName != current.eolChapterName) {
        vars.Log("is it open?" + current.isInEndOfLevelScreen + " (" + old.isInEndOfLevelScreen + ")");
        return vars.CheckSplit("eol__" + current.eolChapterName, "");
    }

    return false;
}
