state("Bloodwash") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.LoadSceneManager = true;
	vars.Helper.GameName = "Bloodwash";
	vars.Helper.AlertLoadless();

	vars.MainMenu = "MainMenuWasher";
	vars.LoadingScreen = "LoadingScreenScene";
	vars.Intro = "IntroScenev2";

	vars.DefaultSplits = new List<string>() { "split_chapter", "split_chapter_3" };
	vars.CompletedSplits = new Dictionary<string, bool>();
	vars.ResetSplits = (Action)(() =>
	{
		foreach (var split in new List<string>(vars.CompletedSplits.Keys))
		{
			vars.CompletedSplits[split] = false;
		}
	});

	var xml = System.Xml.Linq.XDocument.Load(@"Components\Bloodwash.Data.xml").Element("Settings");
	
	vars.AddSetting = (Action<dynamic, string>)((setting, parentId) =>
	{
		string id = setting.Attribute("ID").Value;
		string name = setting.Attribute("Name").Value;
		bool OneTimeSplit = setting.Attribute("OneTimeSplit") != null
		                  ? setting.Attribute("OneTimeSplit").Value == "true" : false;
		
		settings.Add(id, vars.DefaultSplits.Contains(id), name, parentId == "" ? null : parentId);
		if (OneTimeSplit) vars.CompletedSplits[id] = false;

		foreach(var subsetting in setting.Elements("Setting"))
		{
			vars.AddSetting(subsetting, id);
		}
	});

	foreach(var setting in xml.Elements("Setting"))
	{
		vars.AddSetting(setting, "");
	}

}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var slm = mono["SceneLoadingManager"];
		vars.Helper["SceneToLoad"] = mono.MakeString(slm, "current", "sceneToLoad");
		vars.Helper["SceneToUnload"] = mono.MakeString(slm, "current", "sceneToUnload");

		var pv = mono["PlayerVariables"];
		vars.Helper["EvidenceCollected"] = mono.Make<int>(pv, "EvidenceCollected");
		vars.Helper["PurseCollected"] = mono.Make<bool>(pv, "purseCollected");
		vars.Helper["WatchedAllTV"] = mono.Make<bool>(pv, "WatchedAllTV");
		vars.Helper["FoundOuija"] = mono.Make<bool>(pv, "FoundOuija");
		vars.Helper["hasChange"] = mono.Make<bool>(pv, "hasChange");
		vars.Helper["hasPhoneNumber"] = mono.Make<bool>(pv, "hasPhoneNumber");
		vars.Helper["TalkedToCallGirl"] = mono.Make<bool>(pv, "TalkedToCallGirl");
		vars.Helper["BathroomsExplored"] = mono.Make<int>(pv, "BathroomsExplored");
		vars.Helper["PorksyHighScore"] = mono.Make<int>(pv, "PorksyHighScore");
		vars.Helper["RunBumHighScore"] = mono.Make<int>(pv, "RunBumHighScore");

		var am = mono["AchievementsManager"];
		var nai = mono["NpcAchInfo"];
		vars.Helper["npcAchInfos"] = mono.MakeList<IntPtr>(am, "instance", "npcAchInfos");

		var rcc = mono["RushCharacterController"];
		vars.Helper["lockMovement"] = mono.Make<bool>(rcc, "current", "lockMovement");

		var ai = mono["AIController"];
		
		var em = mono["EquipmentManager"];
		var eo = mono.GetClass("EquippableObject", 1);
		vars.Helper["Equipment"] = mono.MakeList<IntPtr>(em, "current", "Equipment");

		vars.Helper["opDidTeleport"] = mono.Make<bool>("OfficePhone", "instance", "didTeleport");
		vars.Helper["wrState"] = mono.Make<int>(ai, "current", "currentState");
		vars.Helper["wrHealth"] = mono.Make<float>(ai, "current", "health");
		
		// No judge me thank you
		vars.ResetMemory = (Action<List<IntPtr>>)(npcAchInfos =>
		{
			foreach(var npcAchInfo in npcAchInfos)
			{
				vars.Helper.Write<bool>(false, npcAchInfo + nai["spokenTo"]);
			}

			vars.Helper.Write["WatchedAllTV"](false);
			vars.Helper.Write["FoundOuija"](false);
			vars.Helper.Write["TalkedToCallGirl"](false);
			vars.Helper.Write["BathroomsExplored"](0);
		});

		vars.ReadNPCSpoken = (Func<IntPtr, bool>)(npcAchInfo =>
		{
			return vars.Helper.Read<bool>(npcAchInfo + nai["spokenTo"]);
		});

		vars.ReadEquipment = (Func<IntPtr, string>)(equippablePointer =>
		{
			return vars.Helper.ReadString(equippablePointer + eo["displayText"]);
		});

		return true;
	});

	current.activeScene = current.loadingScene = "";
	current.wrDead = false;
	vars.ResetSplits();
}

onStart
{
	vars.ResetMemory(current.npcAchInfos);
	vars.ResetSplits();
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded.Count == 0 ? current.activeScene
	                     : vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene
						 : vars.Helper.Scenes.Loaded[0].Name;

	if (!current.wrDead && old.wrHealth > 0 && current.wrHealth <= 0)
	{
		vars.Log("Womb Ripper just died!!!! OH SHIT!");
		current.wrDead = true;
	}
}

start 
{
	return current.activeScene == vars.Intro && old.activeScene == vars.LoadingScreen;    
}

split
{
	// Prologue Split
	if (settings["split_chapter_0"] && !vars.CompletedSplits["split_chapter_0"]
	 && current.activeScene == "IntroScenev2" && current.SceneToLoad == "IntroCredits")
	{
		vars.Log("Split | Completed Prologue");
		vars.CompletedSplits["split_chapter_0"] = true;
		return true;
	}

	// Plaza Split
	if (settings["split_chapter_1"] && !vars.CompletedSplits["split_chapter_1"] && current.activeScene == "IntroScenev2"
	 && !old.opDidTeleport && current.opDidTeleport)
	{
		vars.Log("Split | Completed Plaza");
		vars.CompletedSplits["split_chapter_1"] = true;
		return true;
	}

	// The Womb Ripper Split
	if (settings["split_chapter_3"] && !vars.CompletedSplits["split_chapter_3"] && current.activeScene == "PlazaScene"
	 && current.wrDead && !old.lockMovement && current.lockMovement)
	{
		current.wrDead = false;

		vars.Log("Split | Completed The Womb Ripper");
		vars.CompletedSplits["split_chapter_3"] = true;
		return true;
	}

	// Epilogue Split
	if (settings["split_chapter_5"] && !vars.CompletedSplits["split_chapter_5"] && current.activeScene == "LoadingScreenScene"
	 && old.activeScene == "Morgue" && !current.lockMovement)
	{
		vars.Log("Split | Completed Epilogue");
		vars.CompletedSplits["split_chapter_5"] = true;
		return true;
	}

	// NPC splits
	if (settings["split_npc"])
	{
		for (int i = 0; i < 11; i++)
		{
			string set = "split_npc_" + i;
			if (settings[set] && !vars.CompletedSplits[set]
			 && vars.ReadNPCSpoken(current.npcAchInfos[i]))
			{
				vars.Log("Split | Spoken To NPC " + i);
				vars.CompletedSplits[set] = true;
				return true;
			}
		}
	}

	if (settings["split_purse"] && !old.PurseCollected && current.PurseCollected)
	{
		vars.Log("Split | Collected Purse");
		return true;
	}

	if (settings["split_evidence"] && old.EvidenceCollected < current.EvidenceCollected)
	{
		vars.Log("Split | Collected Evidence: " + old.EvidenceCollected + " -> " + current.EvidenceCollected);
		return true;
	}

	if (settings["split_change"] && !vars.CompletedSplits["split_change"] && !old.hasChange && current.hasChange)
	{
		vars.Log("Split | Got change from the machine");
		vars.CompletedSplits["split_change"] = true;
		return true;
	}

	if (settings["split_janitor"] && !vars.CompletedSplits["split_janitor"] && old.BathroomsExplored < 2 && current.BathroomsExplored >= 2)
	{
		vars.Log("Split | Explored both bathrooms.");
		vars.CompletedSplits["split_janitor"] = true;
		return true;
	}

	if (settings["split_phonenumber"] && !vars.CompletedSplits["split_phonenumber"] && !old.hasPhoneNumber && current.hasPhoneNumber)
	{
		vars.Log("Split | Found the phone number.");
		vars.CompletedSplits["split_phonenumber"] = true;
		return true;
	}

	if (settings["split_callgirl"] && !vars.CompletedSplits["split_callgirl"] && !old.TalkedToCallGirl && current.TalkedToCallGirl)
	{
		vars.Log("Split | Talked to Call Girl");
		vars.CompletedSplits["split_callgirl"] = true;
		return true;
	}

	if (settings["split_tv"] && !vars.CompletedSplits["split_tv"] && !old.WatchedAllTV && current.WatchedAllTV)
	{
		vars.Log("Split | Watched All TV");
		vars.CompletedSplits["split_tv"] = true;
		return true;
	}

	if (settings["split_ouija"] && !vars.CompletedSplits["split_ouija"] && !old.FoundOuija && current.FoundOuija)
	{
		vars.Log("Split | Found the Ouija board.");
		vars.CompletedSplits["split_ouija"] = true;
		return true;
	}

	if (settings["split_porksy"] && !vars.CompletedSplits["split_porksy"] && old.PorksyHighScore < 15 && current.PorksyHighScore >= 15)
	{
		vars.Log("Split | 15 points in Porksy.");
		vars.CompletedSplits["split_porksy"] = true;
		return true;
	}

	if (settings["split_runbum"] && !vars.CompletedSplits["split_runbum"] && old.RunBumHighScore < 5000 && current.RunBumHighScore >= 5000)
	{
		vars.Log("Split | 5000 points in RunBums.");
		vars.CompletedSplits["split_runbum"] = true;
		return true;
	}

	if (settings["split_item"] || settings["split_comic"])
	{
		foreach(var e in current.Equipment)
		{
			string set = "split_" + vars.ReadEquipment(e)
			    .Replace("#", "")
				.Replace("Pick Up ", "")
				.Replace("Pickup ", "")
				.Replace(" ", "_")
				.ToLower();

			if (settings.ContainsKey(set) && settings[set] && !vars.CompletedSplits[set])
			{
				vars.Log("Split | " + set);
				vars.CompletedSplits[set] = true;
				return true;
			}
		}
	}
}

isLoading 
{
	return current.activeScene != current.loadingScene
		|| current.activeScene == vars.LoadingScreen
		|| current.loadingScene == vars.LoadingScreen;
}

reset 
{
	return current.activeScene != current.loadingScene
		&& current.loadingScene == vars.MainMenu
		&& current.activeScene == vars.LoadingScreen;
}