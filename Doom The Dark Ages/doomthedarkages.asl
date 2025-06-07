state("DOOMTheDarkAges") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "DOOM: The Dark Ages";
    vars.Helper.Settings.CreateFromXml("Components/DoomTheDarkAges.Settings.xml");

    vars.ReadString = (Func<IntPtr, string>)(strPtr =>
    {
        return vars.Helper.ReadString(
            512, ReadStringType.UTF8,
            strPtr,
            0x0
        );
    });

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
        { "boss__characters/ahzrak_prince",              "chapter__reckoning" },

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

    #region file io
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

    var DumpLines = (Action<string, string, List<string>>)((parentFolder, name, lines) =>
    {
        Directory.CreateDirectory(parentFolder);
        File.WriteAllLines(Path.Combine(parentFolder, EncodeToFileName(name) + ".cpp"), lines);
    });

    var AlignItems = (Func<List<Tuple<string, string>>, List<Tuple<string, string>>>)(pairs =>
    {
        var longest = 0;
        foreach (var pair in pairs)
        {
            if (pair.Item1.Length > longest && pair.Item1.Length < 120)
            {
                longest = pair.Item1.Length;
            }
        }

        var items = new List<Tuple<string, string>>();
        foreach (var pair in pairs)
        {
            items.Add(new Tuple<string, string>(pair.Item1.PadRight(longest), pair.Item2));
        }
        return items;
    });
    #endregion

    // allow us to cancel operations if the game closes or livesplit shutdowns
    vars.cts = new CancellationTokenSource();
    var SleepAndYield = (Func<int, System.Threading.Tasks.Task<object>>)(async ms =>
    {
        await System.Threading.Tasks.Task.Delay(ms, vars.cts.Token).ConfigureAwait(true);
        vars.cts.Token.ThrowIfCancellationRequested();
        return;
    });

    var idTypeInfoToolsPtr = vars.Helper.ScanRel(18, "48 8b fa 4c 89 41 08 48 8b d9 48 85 D2 74 25 48 8B 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 89 03");
    vars.Log("=> Found idTypeInfoTools pointer at 0x" + idTypeInfoToolsPtr.ToString("X"));
    var WaitUntilTypeInfoToolsInitialised = (Func<System.Threading.Tasks.Task<IntPtr>>)(async () =>
    {
        IntPtr idTypeInfoTools = IntPtr.Zero;
        vars.Log("  => Attempting to load the idTypeInfoTools instance...");
        while (true)
        {
            idTypeInfoTools = vars.Helper.Read<IntPtr>(idTypeInfoToolsPtr);
            if (idTypeInfoTools != IntPtr.Zero)
            {
                vars.Log("    => idTypeInfoTools instance at 0x" + idTypeInfoTools.ToString("X"));
                break;
            }
            vars.Log("    => Still null, retrying...");
            await SleepAndYield(100);
        }

        vars.Log("  => Waiting for classes to be initialised...");
        var a = new Stopwatch();
        a.Start();
        while (!vars.Helper.Read<bool>(idTypeInfoTools + 0xEC))
        {
            vars.Log("    => PostInit not yet handled, waiting...");
            await SleepAndYield(100);
        }
        a.Stop();
        vars.Log("    => Classes initalised after " + a.Elapsed.ToString(@"s\.fff") + "s.");
        return idTypeInfoTools;
    });

    #region class dump
    var DumpEnum = (Action<string, IntPtr>)((parentFolder, enumTypeInfo) =>
    {
        var name = vars.Helper.ReadString(
            512, ReadStringType.UTF8,
            enumTypeInfo + 0x0, // char* name
            0x0
        );
        // Yes, I dumped this enum with the code that you're reading
        string[] enumType = new string[]{ "ENUM_S8", "ENUM_U8", "ENUM_S16", "ENUM_U16", "ENUM_S32", "ENUM_U32", "ENUM_S64", "eh?" };
        var type = vars.Helper.Read<int>(
            enumTypeInfo + 0x10 // enumType type
        );
        // vars.Log("  => Dumping " + name + " (0x" + enumTypeInfo.ToString("X") + ")");

        List<string> lines = new List<string> {
            "/** enum type: enumType." + enumType[type] + " */",
            "enum " + name + " {",
        };

        var values = vars.Helper.Read<IntPtr>(
            enumTypeInfo + 0x20 // enumValueInfo_t* values
        );
        var valuesLength = vars.Helper.Read<int>(
            enumTypeInfo + 0x18 // int valueIndexLength
        ) - 1;
        var ENUM_VALUE_INFO_T_SIZE = 0x10;

        List<Tuple<string, string>> valueStrings = new List<Tuple<string, string>>();
        for (var i = 0; i < valuesLength; i++)
        {
            var valueName = vars.Helper.ReadString(
                512, ReadStringType.UTF8,
                values + ENUM_VALUE_INFO_T_SIZE * i  // [i]
                + 0x0,                               // char* name
                0x0
            );

            // Yes.
            var valueValue = vars.Helper.Read<long>(
                values + ENUM_VALUE_INFO_T_SIZE * i  // [i]
                + 0x8                                // long long value
            );

            var valueStringified = valueValue.ToString();
            valueStrings.Add(new Tuple<string, string>(valueName, valueStringified));
        }

        valueStrings = AlignItems(valueStrings);
        foreach (var v in valueStrings)
        {
            lines.Add("  " + v.Item1 + " = " + v.Item2 + ",");
        }

        lines.Add("}");
        DumpLines(parentFolder, name, lines);
    });

    var DumpVariable = (Func<IntPtr, Tuple<string, string>>)(classVariableInfo_t =>
    {
        var name = vars.ReadString(classVariableInfo_t + 0x10); // char* name
        if (name == "" || name == null)
        {
            return null;
        }

        var type = vars.ReadString(classVariableInfo_t + 0x0); // char* type
        var offset = vars.Helper.Read<int>(classVariableInfo_t + 0x18); // int offset
        var size = vars.Helper.Read<int>(classVariableInfo_t + 0x1C); // int size
        var comment = vars.ReadString(classVariableInfo_t + 0x30); // char* comment

        var fieldInfo = ("    " + type + " " + name + ";");
        var offsetStr = "0x" + offset.ToString("X").PadLeft(5, '0');
        return new Tuple<string, string>(fieldInfo, "// " + offsetStr + " (size: 0x" + size.ToString("X") + ") - " + comment);
    });

    var DumpClass = (Func<string, IntPtr, int>)((parentFolder, classTypeInfo_t) => {
        var name = vars.ReadString(classTypeInfo_t + 0x0); // char* name
        // vars.Log("dumping " + name);
        var superType = vars.ReadString(classTypeInfo_t + 0x8); // char* superType
        var size = vars.Helper.Read<int>(classTypeInfo_t + 0x18); // int size

        var def = "class " + name;
        if (superType != null && superType != "") {
            def += " : " + superType;
        }


        List<string> lines = new List<string> {
            "/** Type Info for '" + name + "'",
            " * ",
        };

        var metaData = vars.Helper.ReadString(
            512, ReadStringType.UTF8,
            classTypeInfo_t + 0x50, // classMetaDataInfo_t* metaData
            0x0,                    // char* metaData
            0x0
        );
        if (metaData != null) {
            lines.AddRange(new List<string> {
                " * metaData: " + metaData,
                " *",
            });
        }

        lines.AddRange(new List<string> {
            " * At the time of dump (these will not mean anything for you):",
            " * - address: 0x" + classTypeInfo_t.ToString("X"),
            " */",
            "",
            "// size: 0x" + size.ToString("X"),
            def + " {",
        });


        var currentVariable = vars.Helper.Read<IntPtr>(classTypeInfo_t + 0x28); // classVariableInfo_t* variables

        var pairs = new List<Tuple<string, string>>();
        while (true) {
            var vari = DumpVariable(currentVariable);
            if (vari == null)
            {
                break;
            }

            pairs.Add(vari);
            currentVariable += 0x58; // size of classVariableInfo_t
        }

        pairs = AlignItems(pairs);
        foreach (var pair in pairs)
        {
            lines.Add(pair.Item1 + " " + pair.Item2);
        }
        lines.Add("}");

        DumpLines(parentFolder, name, lines);

        return 0;
    });

    var DumpTypeDef = (Action<string, IntPtr>)((parentFolder, typedefInfo_t) =>
    {
        var name = vars.ReadString(typedefInfo_t + 0x0); // char* name
        var type = vars.ReadString(typedefInfo_t + 0x8); // char* type
        var ops = vars.ReadString(typedefInfo_t + 0x10); // char* ops
        var size = vars.Helper.Read<int>(typedefInfo_t + 0x18); // int size

        List<string> lines = new List<string> {
            "// ops? " + ops,
            "",
            "typedef " + type + " " + name + "; // size: 0x" + size.ToString("X")
        };

        DumpLines(parentFolder, name, lines);
    });

    var DumpProject = (Action<string, IntPtr>)((parentFolder, project) =>
    {
        var typeInfo = vars.Helper.Read<IntPtr>(
            project + 0x0 // typeInfoGenerated_t typeInfoGen
            + 0x0
        );
        var projectName = vars.Helper.ReadString(
            512, ReadStringType.UTF8,
            typeInfo + 0x0, // char* projectName
            0x0
        );
        var path = Path.Combine(parentFolder, projectName);
        vars.Log("=> Dumping project " + projectName + " to " + path);

        // Enums
        var enumsPath = Path.Combine(path, "enums");
        vars.Log("  => Dumping enums to " + enumsPath);
        var enums = vars.Helper.Read<IntPtr>(typeInfo + 0x8);  // enumTypeInfo_t* enums
        var numEnums = vars.Helper.Read<int>(typeInfo + 0x10); // int numEnums
        for (var i = 0; i < numEnums; i++)
        {
            try {
                DumpEnum(enumsPath, enums + 0x40 * i); // [i] (0x40 is size of enumTypeInfo_t)
            } catch (Exception e) {
                vars.Log("ERROR PROCESS ENUM (" + i + "):");
                vars.Log(e);
            }
        }

        // Classes
        var classesPath = Path.Combine(path, "classes");
        vars.Log("  => Dumping classes to " + classesPath);
        var classes = vars.Helper.Read<IntPtr>(typeInfo + 0x18);  // classTypeInfo_t* classes
        var numClasses = vars.Helper.Read<int>(typeInfo + 0x20); // int numClasses
        for (var i = 0; i < numClasses; i++)
        {
            try {
                DumpClass(classesPath, classes + 0x58 * i); // [i] (0x58 is size of classTypeInfo_t)
            } catch (Exception e) {
                vars.Log("ERROR PROCESS CLASS (" + i + "):");
                vars.Log(e);
            }
        }

        // Typedefs
        var typedefsPath = Path.Combine(path, "typedefs");
        vars.Log("  => Dumping typedefs to " + typedefsPath);
        var typedefs = vars.Helper.Read<IntPtr>(typeInfo + 0x28);  // typedefInfo_t* typedefs
        var numTypedefs = vars.Helper.Read<int>(typeInfo + 0x30); // int numTypedefs
        for (var i = 0; i < numTypedefs; i++)
        {
            try {
                DumpTypeDef(typedefsPath, typedefs + 0x20 * i); // [i] (0x20 is size of typedefInfo_t)
            } catch (Exception e) {
                vars.Log("ERROR PROCESS TYPEDEF (" + i + "):");
                vars.Log(e);
            }
        }
    });

    vars.DumpLiterallyEverything = (Func<System.Threading.Tasks.Task<object>>)(async () =>
    {
        var idTypeInfoTools = await WaitUntilTypeInfoToolsInitialised();

        string docPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
        var basePath = Path.Combine(docPath, "DTDA typeinfo", DateTime.Now.ToString("yyyy-MM-dd"));
        vars.Log("Dumping everything to: " + basePath);


        // These offsets (everything we use below here) are avaiable in the dumps, but of course, we don't know what
        //    they are yet, because to figure out what they are, we'd have to already know what they are.
        // Let's hope these are stable, so that this shit always works.

        // hardcoded to 2
        for (var projectIdx = 0; projectIdx < 2; projectIdx++)
        {
            DumpProject(
                basePath,
                idTypeInfoTools + 0x0 // idArray < idTypeInfoTools::registeredTypeInfo_t , 2 > generatedTypeInfo
                + 0x38 * projectIdx   // [projectIdx]
            );
        }
        return;
    });
    #endregion

    System.Threading.Tasks.Task.Run((Func<System.Threading.Tasks.Task<object>>)(async () => {
        IntPtr idTypeInfoTools = IntPtr.Zero;

        // class name -> (project index, class index)
        var classLocationMap = new Dictionary<string, Tuple<int, int>>();
        var BuildClassLocationMap = (Func<System.Threading.Tasks.Task<object>>)(async () =>
        {
            vars.Log("=> Building class location map cache...");
            idTypeInfoTools = await WaitUntilTypeInfoToolsInitialised();

            for (var projectIdx = 0; projectIdx < 2; projectIdx++)
            {
                var project = idTypeInfoTools
                    + 0x0 // idArray < idTypeInfoTools::registeredTypeInfo_t , 2 > generatedTypeInfo
                    + 0x38 * projectIdx;   // [projectIdx]

                var typeInfo = vars.Helper.Read<IntPtr>(
                    project + 0x0 // typeInfoGenerated_t typeInfoGen
                );
                var projectName = vars.Helper.ReadString(
                    512, ReadStringType.UTF8,
                    typeInfo + 0x0, // char* projectName
                    0x0
                );
                vars.Log("  => Getting classes under " + projectName + "...");

                var classes = vars.Helper.Read<IntPtr>(typeInfo + 0x18); // classTypeInfo_t* classes
                var numClasses = vars.Helper.Read<int>(typeInfo + 0x20); // int numClasses
                for (var classIdx = 0; classIdx < numClasses; classIdx++)
                {
                    var name = vars.ReadString(
                        classes + 0x58 * classIdx // [classIdx] (0x58 is size of classTypeInfo_t)
                        + 0x0                     // char* name
                    );

                    if (name == null || name == "")
                    {
                        vars.Log("    => Finished processing " + classIdx + " classes.");
                        break;
                    }

                    classLocationMap.Add(name, new Tuple<int, int>(projectIdx, classIdx));
                }
            }
            return;
        });

        // Cache for the classes we've already introspected
        // class name -> (variable name -> offset)
        var classOffsetCache = new Dictionary<string, Dictionary<string, int>>();
        var GetClassVariableMap = (Func<string, Dictionary<string, int>>)(className =>
        {
            Dictionary<string, int> map;
            if (classOffsetCache.TryGetValue(className, out map))
            {
                return map;
            }

            map = new Dictionary<string, int>();
            vars.Log("=> Loading " + className + " variables and their offsets...");

            Tuple<int, int> classLocation;
            if (!classLocationMap.TryGetValue(className, out classLocation))
            {
                vars.Log("  => ERROR: Unable to find class " + className + " in location map");
                return map;
            }

            var projectIdx = classLocation.Item1;
            var classIdx = classLocation.Item2;
            vars.Log("  => Has location " + projectIdx + ", " + classIdx);

            var currentVariable = vars.Helper.Read<IntPtr>(
                idTypeInfoTools
                + 0x0                 // idArray < idTypeInfoTools::registeredTypeInfo_t , 2 > generatedTypeInfo
                + 0x38 * projectIdx   // [projectIdx]
                + 0x0,                   // typeInfoGenerated_t typeInfoGen
                0x18,               // classTypeInfo_t* classes
                0x58 * classIdx      // [i] (0x58 is size of classTypeInfo_t)
                + 0x28                  // classVariableInfo_t* variables
            );
            vars.Log("  => Variables array starts at 0x" + currentVariable.ToString("X"));

            for (var variableIdx = 0; true; variableIdx++) {
                var name = vars.ReadString(currentVariable + 0x10); // char* name
                if (name == null || name == "")
                {
                    vars.Log("  => Loaded " + variableIdx + " variables");
                    break;
                }

                var offset = vars.Helper.Read<int>(currentVariable + 0x18); // int offset
                vars.Log("    => 0x" + offset.ToString("X") + " " + name);
                map.Add(name, offset);

                currentVariable += 0x58; // size of classVariableInfo_t
            }

            classOffsetCache.Add(className, map);
            return map;
        });

        // Does not include superclasses, use the superclass name for those offsets
        var GetOffset = (Func<string, string, int>)((className, variableName) =>
        {
            var offsetMap = GetClassVariableMap(className);
            if (offsetMap == null)
            {
                return -1;
            }

            int offset = -1;
            if (offsetMap.TryGetValue(variableName, out offset))
            {
                return offset;
            }

            vars.Log("  => ERROR: Unable to find " + variableName + " in " + className);
            return -1;
        });

        await BuildClassLocationMap();

        // the root of all evil
        vars.idGameSystemLocal = vars.Helper.ScanRel(0x6, "FF 50 40 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0");
        vars.Log("=> Found idGameSystemLocal at 0x" + vars.idGameSystemLocal.ToString("X"));

        // enum idGameSystemLocal::state_t {
        //   GAME_STATE_MAIN_MENU = 0,
        //   GAME_STATE_LOADING = 1,
        //   GAME_STATE_INGAME = 2,
        // }
        vars.Helper["gameState"] = vars.Helper.Make<int>(
            vars.idGameSystemLocal + GetOffset("idGameSystemLocal", "state") // idGameSystemLocal::state_t
        );
        vars.Helper["map"] = vars.Helper.MakeString(
            vars.idGameSystemLocal + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x20, // idStrStatic < 1024 > mapName (does not show up in dumps)
            0x0
        );

        // the idPlayer was pointer scanned for, and walked back - we don't have type information for
        //   idMapInstance, nor whatever the class is at 0x1988
        vars.Helper["playerVelX"] = vars.Helper.Make<float>(
            vars.idGameSystemLocal + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988, // ??
            0xC0,   // an idPlayer
            GetOffset("idPlayer", "idPlayerPhysicsInfo"), // idPlayerPhysicsInfo
            GetOffset("idPlayerPhysicsInfo", "current") // playerPState_t
            + GetOffset("playerPState_t", "velocity") // idVec3 velocity
            + GetOffset("idVec3", "x") // float x
        );
        vars.Helper["playerVelY"] = vars.Helper.Make<float>(
            vars.idGameSystemLocal + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988, // ??
            0xC0,   // an idPlayer
            GetOffset("idPlayer", "idPlayerPhysicsInfo"), // idPlayerPhysicsInfo
            GetOffset("idPlayerPhysicsInfo", "current") // playerPState_t
            + GetOffset("playerPState_t", "velocity") // idVec3
            + GetOffset("idVec3", "y") // float
        );
        vars.Helper["playerVelZ"] = vars.Helper.Make<float>(
            vars.idGameSystemLocal + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988, // ??
            0xC0,   // an idPlayer
            GetOffset("idPlayer", "idPlayerPhysicsInfo"), // idPlayerPhysicsInfo
            GetOffset("idPlayerPhysicsInfo", "current") // playerPState_t
            + GetOffset("playerPState_t", "velocity") // idVec3
            + GetOffset("idVec3", "z") // float
        );

        // shrug
        var TOLERANCE = 0.05;
        vars.PlayerIsMoving = (Func<dynamic, bool>)(state =>
        {
            // we don't check Y cause sometimes you jump in the cutscene
            //   and who really cares about that anyways
            return state.playerVelX > TOLERANCE || state.playerVelY > TOLERANCE;
        });

        #region Menus
        vars.Helper["hudMenus"] = vars.Helper.Make<IntPtr>(
            vars.idGameSystemLocal
             + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988, // ??
            0xC0, // an idPlayer
            GetOffset("idPlayer", "playerHud") // idHUD
            + GetOffset("idHUD", "menus") // idList < idMenu* >
        );
        vars.Helper["hudMenusSize"] = vars.Helper.Make<int>(
            vars.idGameSystemLocal
             + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988, // ??
            0xC0, // an idPlayer
            GetOffset("idPlayer", "playerHud") // idHUD
            + GetOffset("idHUD", "menus") // idList < idMenu* >
            + 0x8
        );

        // only defined when we're in the end of level screen
        vars.Helper["eolChapterName"] = vars.Helper.MakeString(
            vars.idGameSystemLocal
            + 0x48, // idMapInstance mapInstance
            0x1988,  // ??
            0xC0,    // an idPlayer
            GetOffset("idPlayer", "playerHud") // idHUD
            + GetOffset("idHUD", "menus"), // idList < idMenu* >
            0x8 * 2, // [2] ("playermenu")
            GetOffset("idMenu", "titanScreens") // idListMap < idAtomicString , idMenuElement * >
            + 0x18,  // idList < idMenuElement * > sortedValueList
            0x8 * 2, // [2] ("playermenu/eol_mission_complete")
            GetOffset("idUIElement", "rootWidgetNew") // idSharedPtr < idUIWidget > (idUIWidget "ui/screens")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidget", "modelInterface") // idSharedPtr < idUIWidgetModelInterface >
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModelInterface", "model") // idSharedPtr < idUIWidgetModel > (idUIWidgetModel_EOL_Mission_Complete)
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModel_EOL_Mission_Complete", "chapterName"), // idDeclString
            GetOffset("idResource", "name"), // idAtomicString
            0x0
        );
        vars.Helper["eolChapterName"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

        // Jesus Fucking Christ
        vars.Helper["bossHealthBarShown"] = vars.Helper.Make<bool>(
            vars.idGameSystemLocal
            + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988,  // ??
            0xC0,    // an idPlayer
            GetOffset("idPlayer", "playerHud") // idHUD
            + GetOffset("idHUD", "elements")   // idGrowableList < idHUDElement * >
            + 0x0,   // idHUDElement list
            0x8 * 2, // [2] ("hud")
            GetOffset("idUIElement", "rootWidgetNew") // idSharedPtr < idUIWidget > (idUIWidget "ui/screens")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            // Okay breathe for a moment
            GetOffset("idUIWidget", "children") // idList < idSharedPtr < idUIWidget > >
            + 0x0,   // idSharedPtr < idUIWidget > list
            0x8 * 7  // [7] ("ui/screens/hud_screen_boss_health")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            GetOffset("idUIWidget", "children") // idList < idSharedPtr < idUIWidget > >
            + 0x0,   // idSharedPtr < idUIWidget > list
            0x8 * 0  // [0] ("ui/prefabs/hud_boss_health_bar")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            GetOffset("idUIWidget", "modelInterface") // idSharedPtr < idUIWidgetModelInterface >
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModelInterface", "model") // idSharedPtr < idUIWidgetModel > (idUIWidgetModel_Hud_Boss_HealthBar)
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModel_Hud_Boss_HealthBar", "isShown") // bool
        );

        vars.Helper["bossHealth"] = vars.Helper.Make<float>(
            vars.idGameSystemLocal
            + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988,  // ??
            0xC0,    // an idPlayer
            GetOffset("idPlayer", "playerHud") // idHUD
            + GetOffset("idHUD", "elements")   // idGrowableList < idHUDElement * >
            + 0x0,   // idHUDElement list
            0x8 * 2, // [2] ("hud")
            GetOffset("idUIElement", "rootWidgetNew") // idSharedPtr < idUIWidget > (idUIWidget "ui/screens")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            // Okay breathe for a moment
            GetOffset("idUIWidget", "children") // idList < idSharedPtr < idUIWidget > >
            + 0x0,   // idSharedPtr < idUIWidget > list
            0x8 * 7  // [7] ("ui/screens/hud_screen_boss_health")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            GetOffset("idUIWidget", "children") // idList < idSharedPtr < idUIWidget > >
            + 0x0,   // idSharedPtr < idUIWidget > list
            0x8 * 0  // [0] ("ui/prefabs/hud_boss_health_bar")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            GetOffset("idUIWidget", "modelInterface") // idSharedPtr < idUIWidgetModelInterface >
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModelInterface", "model") // idSharedPtr < idUIWidgetModel > (idUIWidgetModel_Hud_Boss_HealthBar)
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModel_Hud_Boss_HealthBar", "isShown") // float
        );

        // idGameSystemLocal.??.player.playerHud.elements[2].children[7].children[0].children[4].model.text.key
        vars.Helper["bossName"] = vars.Helper.MakeString(
            vars.idGameSystemLocal
            + GetOffset("idGameSystemLocal", "mapInstance"), // idMapInstance
            0x1988,  // ??
            0xC0,    // an idPlayer
            GetOffset("idPlayer", "playerHud") // idHUD
            + GetOffset("idHUD", "elements")   // idGrowableList < idHUDElement * >
            + 0x0,   // idHUDElement list
            0x8 * 2, // [2] ("hud")
            GetOffset("idUIElement", "rootWidgetNew") // idSharedPtr < idUIWidget > (idUIWidget "ui/screens")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            // Okay breathe for a moment
            GetOffset("idUIWidget", "children") // idList < idSharedPtr < idUIWidget > >
            + 0x0,   // idSharedPtr < idUIWidget > list
            0x8 * 7  // [7] ("ui/screens/hud_screen_boss_health")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            GetOffset("idUIWidget", "children") // idList < idSharedPtr < idUIWidget > >
            + 0x0,   // idSharedPtr < idUIWidget > list
            0x8 * 0  // [0] ("ui/prefabs/hud_boss_health_bar")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            GetOffset("idUIWidget", "children") // idList < idSharedPtr < idUIWidget > >
            + 0x0,   // idSharedPtr < idUIWidget > list
            0x8 * 4  // [0] ("ui/prefabs/hud_boss_health_bar")
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer

            GetOffset("idUIWidget", "modelInterface") // idSharedPtr < idUIWidgetModelInterface >
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModelInterface", "model") // idSharedPtr < idUIWidgetModel > (idUIWidgetModel_Text)
            + 0x0,   // idSharedPtrData data
            0x8,     // interlockedPointer_t < void > pointer
            GetOffset("idUIWidgetModel_Text", "text"), // idDeclString
            GetOffset("idResource", "name"), // idAtomicString (looks like "characters/ahzrak_prince")
            0x0
        );
        vars.Helper["bossName"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

        vars.GetActiveScreens = (Func<HashSet<string>>)(() => {
            var ret = new HashSet<string>();

            // I have a hunch that it's always at i=2, but do our due diligence...
            for (var i = 0; i < current.hudMenusSize; i++) {
                var currentScreen = vars.Helper.ReadString(
                    512, ReadStringType.UTF8,
                    current.hudMenus + i * 0x8,
                    GetOffset("idMenu", "currentScreen") // idMenu::menuScreenId_t
                    + GetOffset("idMenu::menuScreenId_t", "titanId"), // idAtomicString
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
            vars.idGameSystemLocal
             + GetOffset("idGameSystemLocal", "questSystem"), // idQuestSystem
            GetOffset("idQuestSystem", "quests") // idList<idQuest*>
            + 0x0 // idQuest* list
        );
        vars.Helper["questsSize"] = vars.Helper.Make<int>(
            vars.idGameSystemLocal
             + GetOffset("idGameSystemLocal", "questSystem"), // idQuestSystem
            GetOffset("idQuestSystem", "quests") // idList<idQuest*>
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
                + GetOffset("idQuest", "questSteps"), // idList < idQuestStep >
                stepIdx * QUEST_STEP_SIZE // [questStepIdx]
                + GetOffset("idQuestStep", "progress") // idQuestRequirementProgress
                + GetOffset("idQuestRequirementProgress", "trackedValue") // unsigned int
            );
        });
        vars.ReadQuestName = (Func<int, string>)(questIdx =>
        {
            return vars.Helper.ReadString(
                512, ReadStringType.UTF8,
                current.quests + questIdx * QUEST_SIZE // [questIdx]
                + GetOffset("idQuest", "questDef"), // idDeclQuestDef
                GetOffset("idDeclQuestDef", "questId"), // idStr
                0x0
            );
        });

        vars.LogAllQuests = (Action)(() =>
        {
            // var start = DateTime.Now;
            for (var i = 0; i < current.questsSize; i++)
            {
                var questStatus = vars.ReadQuestStatus(i);
                var questName = vars.ReadQuestName(i);

                vars.Log("quest " + i + " " + questName + " is in status " + questStatus + " (0x" + (current.quests + i * QUEST_SIZE).ToString("X") + ")");
            }
        });

        vars.Log("  => Loading complete!");
        vars.finishedLoading = true;
        return;
    }), vars.cts.Token);
    #endregion

    current.hasTimerStartedInThisLoadYet = false;

    // we do some loading in another thread to unblock the main thread and keep LS responsive -
    // we need to, however, block the ASL from attempting to do anything until that loading is done.
    vars.finishedLoading = false;
}

update
{
    // don't do anything until we're done loading everything - see init{}
    if (!vars.finishedLoading)
    {
        return false;
    }

    vars.Helper.Update();
    vars.Helper.MapPointers();

    current.isInEndOfLevelScreen = vars.IsInEndOfLevelScreen();
    // map value that changes at a more favourable point
    current.activeMap = current.gameState == 1
        ? ((IDictionary<string, object>) current).ContainsKey("activeMap")
            ? current.activeMap
            : "no map"
        : current.map;

    if (old.gameState != 2 && current.gameState == 1)
    {
        current.hasTimerStartedInThisLoadYet = false;
    }

    vars.Watch(old, current, "gameState");
    vars.Watch(old, current, "map");
    vars.Watch(old, current, "activeMap");
    vars.Watch(old, current, "isInEndOfLevelScreen");
    vars.Watch(old, current, "eolChapterName");
    vars.Watch(old, current, "bossName");
    vars.Watch(old, current, "bossHealthBarShown");
    vars.Watch(old, current, "hasTimerStartedInThisLoadYet");

    if(settings["Loading"])
    {
        vars.SetTextComponent("GameState:",current.gameState.ToString());
    }

    if(settings["map"])
    {
        vars.SetTextComponent(" ",current.map.ToString());
    }

    if(settings["velocity_hori"])
    {
        var horiVel = Math.Sqrt(current.playerVelX * current.playerVelX + current.playerVelY * current.playerVelY);
        vars.SetTextComponent("Horizontal Velocity ", horiVel.ToString("0.00"));
    }

    if (settings["velocity_vert"])
    {
        vars.SetTextComponent("Vertical Velocity ", current.playerVelZ.ToString("0.00"));
    }

    if (settings["boss_name"])
    {
        vars.SetTextComponent("Boss Name ", current.bossName ?? "(none)");
    }

    if (settings["boss_health"])
    {
        vars.SetTextComponent("Boss Health ", current.bossHealth.ToString("0.00"));
    }

    if (settings["boss_bar_shown"])
    {
        vars.SetTextComponent("Boss Healthbar Shown ", current.bossHealthBarShown.ToString());
    }
}

onStart
{
    vars.Log("===== TIMER STARTED =====");
    current.hasTimerStartedInThisLoadYet = true;

    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();
    vars.CompletedQuests.Clear();

    // vars.LogAllQuests();
    // vars.DumpLiterallyEverything();
}

onReset
{
    vars.Log("===== TIMER RESET =====");
}

isLoading
{
    // don't do anything until we're done loading everything - see init{}
    if (!vars.finishedLoading)
    {
        return false;
    }

    return current.gameState == 1
        || current.isInEndOfLevelScreen
        || current.gameState == 0;
}

start
{
    // don't do anything until we're done loading everything - see init{}
    if (!vars.finishedLoading)
    {
        return false;
    }

    // from the main menu, every chapter except the first
    if (settings["start_any_chapter"]
     && current.activeMap != old.activeMap
     && old.activeMap == "game/shell/shell"
     && current.activeMap != "game/sp/m1_intro/m1_intro"
    ) {
        return true;
    }

    // first split
    return !current.hasTimerStartedInThisLoadYet
        && current.activeMap == "game/sp/m1_intro/m1_intro"
        && !vars.PlayerIsMoving(old)
        && vars.PlayerIsMoving(current);
}

split
{
    // don't do anything until we're done loading everything - see init{}
    if (!vars.finishedLoading)
    {
        return false;
    }

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

    if (old.bossHealthBarShown && !current.bossHealthBarShown) {
        vars.Log("guy: " + current.bossName);
        return vars.CheckSplit("boss__" + current.bossName, "");
    }
}

reset
{
    // don't do anything until we're done loading everything - see init{}
    if (!vars.finishedLoading)
    {
        return false;
    }

    if (settings["reset_auto_first_chapter"]
     && old.gameState == 2 && current.gameState == 1
     && current.activeMap == "game/sp/m1_intro/m1_intro"
     && !current.isInEndOfLevelScreen
    )
    {
        return true;
    }

    return false;
}

exit
{
    timer.IsGameTimePaused = true;
}