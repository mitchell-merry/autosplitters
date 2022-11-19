state("Bendy and the Dark Revival") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Bendy and the Dark Revival";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gm = mono["GameManager"];
		vars.Helper["GameState"] = mono.Make<int>(gm, "m_Instance", "GameState");
		vars.Helper["IsLoading"] = mono.Make<bool>(gm, "m_Instance", "m_AsyncLoader", "m_IsLoading");
		vars.Helper["IsGameLoaded"] = mono.Make<bool>(gm, "m_Instance", "isGameLoaded");
		vars.Helper["IsGameMenu"] = mono.Make<bool>(gm, "m_Instance", "m_IsGameMenu");

		// hashset of currently loading sections, 0x30 is the _count field of the HashSet
		vars.Helper["SectionLoadingCount"] = mono.Make<int>(gm, "m_Instance", "SectionManager", "m_SectionsLoading", 0x30);
		// DEBUGGING, IGNORE
		// vars.Helper["SectionsLoading"] = mono.MakeArray<IntPtr>(gm, "m_Instance", "SectionManager", "m_SectionsLoading", 0x18);
		// vars.Helper["Sections"] = mono.Make<IntPtr>(gm, "m_Instance", "SectionManager", "m_Sections");

		// vars.ReadSlot = (Func<IntPtr, int>)(slot =>
		// {
		// 	return vars.Helper.Read<int>(slot + 0x18);
		// });

		// vars.ReadEntries = (Func<IntPtr, int, List<dynamic>>)((dictionary, maxEntries) =>
		// {
		// 	// entries are 0x18 from the dict
		// 	var ENTRIES_OFFSET = 0x18;

		// 	// data about the entries array
		// 	var LENGTH_OFFSET = 0x18;
		// 	var ITEMS_OFFSET = 0x20;
		// 	// each item is a struct instead of a reference to another object
		// 	var ITEM_SIZE = 0x18;

		// 	// where the key/value are in each item
		// 	var KEY_OFFSET = 0x8;
		// 	var VAL_OFFSET = 0x10;

		// 	var entries = vars.Helper.Read<IntPtr>(dictionary + ENTRIES_OFFSET);
		// 	var length = vars.Helper.Read<int>(entries + LENGTH_OFFSET);

		// 	var ret = new List<dynamic>();
		// 	for(var i = 0; i < length && (maxEntries == -1 || i < maxEntries); i++)
		// 	{
		// 		var entryPointer = entries + ITEMS_OFFSET + (i * ITEM_SIZE);

		// 		var key = vars.Helper.Read<int>(entryPointer + KEY_OFFSET);
		// 		if (key == 0) continue;

		// 		var val = vars.Helper.Read<IntPtr>(entryPointer + VAL_OFFSET);

		// 		dynamic entry = new ExpandoObject();
		// 		entry.Key = key;
		// 		entry.Value = val;
		// 		ret.Add(entry);
		// 	}

		// 	return ret;
		// });

		// var s = mono["Section"];
		// var sdo = mono["SectionDataObject"];

		// vars.ReadSection = (Func<IntPtr, dynamic>)(section => {
		// 	dynamic ret = new ExpandoObject();

		// 	var id = vars.Helper.Read<int>(section + s["m_SectionID"]);
		// 	var IsActive = vars.Helper.Read<bool>(section + s["IsActive"]);
		// 	var IsReady = vars.Helper.Read<bool>(section + s["IsReady"]);
		// 	var IsInitialized = vars.Helper.Read<bool>(section + s["IsInitialized"]);
		// 	var IsLoaded = vars.Helper.Read<bool>(section + s["IsLoaded"]);
		// 	var IsDisposed = vars.Helper.Read<bool>(section + s["IsDisposed"]);
		// 	var IsDestroyed = vars.Helper.Read<bool>(section + s["IsDestroyed"]);
		// 	var IsComplete = vars.Helper.Read<bool>(section + s["m_Data"], sdo["m_IsComplete"]);

		// 	ret.id = id;
		// 	ret.IsActive = IsActive;
		// 	ret.IsReady = IsReady;
		// 	ret.IsInitialized = IsInitialized;
		// 	ret.IsLoaded = IsLoaded;
		// 	ret.IsDisposed = IsDisposed;
		// 	ret.IsDestroyed = IsDestroyed;
		// 	ret.IsComplete = IsComplete;

		// 	return ret;
		// });

		return true;
	});
}

onStart
{
	// DEBUGGING, IGNORE

	// vars.Log(current.GameState);
	// vars.Log(current.IsLoading);
	// vars.Log(current.IsGameLoaded);
	// vars.Log(current.IsGameMenu);
	// vars.Log(current.activeScene);
	// vars.Log(current.loadingScene);

	// vars.Log("Loaded count: " + vars.Helper.Scenes.Loaded.Count);
	// foreach (var scene in vars.Helper.Scenes.Loaded)
	// {
	// 	vars.Log("---" + scene.Name);
	// }

	// var entries = vars.ReadEntries(current.Sections, 10);
	// vars.Log("Section count: " + entries.Count);
	// foreach (var section in entries)
	// {
	// 	vars.Log(section.Key + ":");
		
	// 	var sectionObj = vars.ReadSection(section.Value);
	// 	vars.Log("--IsActive: " + sectionObj.IsActive);
	// 	vars.Log("--IsReady: " + sectionObj.IsReady);
	// 	vars.Log("--IsInitialized: " + sectionObj.IsInitialized);
	// 	vars.Log("--IsLoaded: " + sectionObj.IsLoaded);
	// 	vars.Log("--IsDisposed: " + sectionObj.IsDisposed);
	// 	vars.Log("--IsDestroyed: " + sectionObj.IsDestroyed);
	// 	vars.Log("--IsComplete: " + sectionObj.IsComplete);
	// }

	// vars.Log("hi");
	// vars.Log("Sections Loading: " + vars.Helper["SectionsLoading"].Current.Length);
	// vars.Log("hi");
	// foreach (var slot in current.SectionsLoading)
	// {
	// 	vars.Log(slot + ":");
	// 	var val = vars.ReadSlot(slot);
	// 	vars.Log("--- " + val);
	// }
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

	if(current.activeScene != old.activeScene) vars.Log("a: \"" + old.activeScene + "\", \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("l: \"" + old.loadingScene + "\", \"" + current.loadingScene + "\"");

	vars.Watch("GameState");
	vars.Watch("IsLoading");
	vars.Watch("IsGameLoaded");
	vars.Watch("IsGameMenu");
}

isLoading
{
	return current.SectionLoadingCount > 0;
}