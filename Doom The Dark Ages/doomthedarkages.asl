state("DOOMTheDarkAges") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "DOOM: The Dark Ages";
    vars.Helper.Settings.CreateFromXml("Components/DoomTheDarkAges.Settings.xml");
    
    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });
    
    vars.CompletedSplits = new HashSet<string>();
    
    vars.Helper.AlertLoadless();

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

    settings.Add("Variable Information", true, "Variable Information");
	settings.Add("Loading", false, "Current Loading", "Variable Information");
    settings.Add("Mission", false, "Current Mission", "Variable Information");
}

init
{
    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key =>
    {
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

    #region class inference
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

    vars.ReadClassThing = (Func<IntPtr, int, int>)((classPtr, classIdx) => {
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
    #endregion

    vars.idGameSystemLocal = vars.Helper.ScanRel(0x6, "FF 50 40 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0");
    vars.Log("Found idGameSystemLocal at 0x" + vars.idGameSystemLocal.ToString("X"));

    // enum GameState {
    //   GAME_STATE_MAIN_MENU = 0,
    //   GAME_STATE_LOADING = 1,
    //   GAME_STATE_INGAME = 2,
    // }
    vars.Helper["gameState"] = vars.Helper.Make<int>(vars.idGameSystemLocal + 0x40);
    vars.Helper["mission"] = vars.Helper.MakeString(vars.idGameSystemLocal + 0xA8 + 0x18);

    #region Quests
    vars.Helper["quests"] = vars.Helper.Make<IntPtr>(
        vars.idGameSystemLocal + 0x1A30, // idQuestSystem questSystem
        0x0 // idList<idQuest*> quests.idQuest* list
    );
    vars.Helper["questsSize"] = vars.Helper.Make<int>(
        vars.idGameSystemLocal + 0x1A30, // idQuestSystem questSystem
        0x8 // idList<idQuest*> quests.int num
    );

    var QUEST_SIZE = 0xB8;

    // enum idQuestStatus {
    //     QUEST_STATUS_LOCKED_AND_HIDDEN = 0
    //     QUEST_STATUS_LOCKED = 1
    //     QUEST_STATUS_UNLOCKED = 2
    //     QUEST_STATUS_IN_PROGRESS = 3
    //     QUEST_STATUS_COMPLETE = 4
    //     QUEST_STATUS_FAILED = 5
    // }
    vars.ReadQuestStatus = (Func<int, int>)(questIdx => {
        return vars.Helper.Read<int>(
            current.quests + questIdx * QUEST_SIZE + 0x8 // [questIdx].idQuestStatus questStatus
        );
    });
    vars.ReadQuestName = (Func<int, string>)(questIdx => {
        return vars.Helper.ReadString(
            512, ReadStringType.UTF8,
            current.quests + questIdx * QUEST_SIZE + 0x0, // [questIdx].idDeclQuestDef questDef
            0x88, // idStr questId
            0x0
        );
    });

    #endregion

    vars.CompletedQuests = new HashSet<int>();
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    // current.shieldSawQuestStatus = vars.ReadQuestStatus(115);
    // vars.Log(    current.shieldSawQuestStatus);

    
    var quest = current.quests;
    for (var i = 0; i < current.questsSize; i++)
    {
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
    }


    if(settings["Loading"]) 
    {
        vars.SetTextComponent("GameState:",current.gameState.ToString());
    }

    if(settings["Mission"]) 
    {
        vars.SetTextComponent(" ",current.mission.ToString());
    }
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log("mission: " + current.mission);

    // quests
    // var start = DateTime.Now;
    // var quest = current.quests;
    // for (var i = 0; i < current.questsSize; i++) {

    //     var questStatus = vars.ReadQuestStatus(i);
    //     // if (questStatus == 4) {
    //         var questName = vars.ReadQuestName(i);

    //         vars.Log("<Setting Id=\"quest_" + i + "\" Label=\"" + i + " " + questName + "\" State=\"false\" />");
    //     // }

    // }
    // var elapsed = DateTime.Now - start;
    // vars.Log(elapsed);

    // DUMP STUFF:
    // string docPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
    // Directory.CreateDirectory(Path.Combine(docPath, "DTDA typeinfo"));
    // var classListMaybeStart = (IntPtr) 0x148A88FE8;148A7F598
    // var classArray = (IntPtr) 0x147F49118;
    // var classArraySize = (IntPtr) 0x147F49120;

    // var CLASS_SIZE = 0x58;

    // var classArrayS = vars.Helper.Read<int>(classArraySize);
    // var currentClass = vars.Helper.Read<IntPtr>(classArray);
    // for (var i = 0; i < classArrayS; i++) {
    //     try {
    //         vars.ReadClassThing(currentClass, i);
    //     } catch (Exception e) {
    //         vars.Log(e);
    //     }
        
    //     currentClass += CLASS_SIZE;
    // }
}

isLoading
{
    return current.gameState == 1;
}

start
{
    // if (old.mission == "game/shell/shell" && current.mission != "game/shell/shell")
    // {
    //     timer.IsGameTimePaused = true;
    //     return true;
    // }
}

split
{
    return old.mission != current.mission && current.mission != "game/shell/shell";
}
