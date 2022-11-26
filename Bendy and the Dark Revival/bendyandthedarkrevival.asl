state("Bendy and the Dark Revival") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Bendy and the Dark Revival";
	vars.Helper.AlertLoadless();

	vars.Helper.Settings.CreateFromXml("Components/BATDR.Settings.xml");
	vars.SettingAliases = new Dictionary<string, List<string>>() {
		{ "obj_10602", new List<string>() { "ch_intro" }}
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

		var sdo = mono["SectionDataObject"];
		var cdo = mono["CutsceneDataObject"];
		// Grab the status of a specific section instead of reading all the sections
		// ..., 0x20 (m_Values), 0x10 (items), 0x28 (0x20 + 0x8*[section]), 0x20 (m_CutsceneData), 0x20 (m_Values), 0x10 (items), 0x80 (0x20 + 0x8*[cutscene]), 0x18 (m_Status)
		vars.Helper["sections"] = mono.Make<IntPtr>(gm, "m_Instance", "GameData", "CurrentSave", "m_DataDirectories", "m_SectionDirectory", 0x20);
		vars.ReadCutsceneStatus = (Func<IntPtr, int, int, int>)((sections, section, cutscene) =>
		{
			return vars.Helper.Read<int>(sections + 0x10, 0x20 + 0x8*section, sdo["m_CutsceneData"], 0x20, 0x10, 0x20 + 0x8*cutscene, cdo["m_Status"]);
		});

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

	vars.Setting = (Func<string, bool>)(key =>
	{
		if (!settings.ContainsKey(key)) return false;
		if (settings[key]) return true;
		if (!vars.SettingAliases.ContainsKey(key)) return false;

		foreach(var k in vars.SettingAliases[key])
		{
			if (settings[k]) return true;
		}

		return false;
	});

	vars.ResetSplits();
}

onStart
{
	timer.IsGameTimePaused = current.IsLoading;
	vars.ResetSplits();
	foreach(var task in current.tasks)
	{
		var tdo = vars.ReadTDO(task);
		vars.Log("==" + tdo.ID + ": " + tdo.IsComplete);
	}
}

update
{
	current.IsLoadingSection = vars.Helper.Read<IntPtr>(current.gm + 0xD0) != IntPtr.Zero;
	current.IsPaused = current.PauseMenuActive && current.GameState == 4 && current.GMIsPaused && current.IsPauseReady;

	current.IsLoading = current.IsLoadingSection || (settings["remove_paused"] && current.IsPaused);
	current.standUpCutsceneStatus = vars.ReadCutsceneStatus(current.sections, 1, 12);
	current.inkDemonIntroCSStatus = vars.ReadCutsceneStatus(current.sections, 8, 7);
}

start
{
	// Inactive -> Active
	return old.standUpCutsceneStatus == 0 && current.standUpCutsceneStatus == 2;
}

split
{
	if (settings["ch_1"] && (!vars.CompletedSplits.ContainsKey("ch_1") || !vars.CompletedSplits["ch_1"]) && old.inkDemonIntroCSStatus == 2 && current.inkDemonIntroCSStatus == 3)
	{
		vars.Log("Chapter 1 Complete");
		vars.CompletedSplits["ch_1"] = true;
		return true;
	}

	foreach(var task in current.tasks)
	{
		var tdo = vars.ReadTDO(task);
		string key = "obj_" + tdo.ID;
		if (vars.Setting(key) && (!vars.CompletedSplits.ContainsKey(key) || !vars.CompletedSplits[key]) && tdo.IsComplete)
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
		if (vars.Setting(key) && (!vars.CompletedSplits.ContainsKey(key) || !vars.CompletedSplits[key]))
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