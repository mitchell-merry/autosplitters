// This autosplitter was kindly written in assistance with Ero

state("The Whitetail Incident") {}

startup { 
	vars.Scenes = new List<string>
	{
		"MainMenu",
		"Cutscene01",
		"Map01",
		"Cutscene02",
		"Map02",
		"Cutscene03",
		"Map03",
		"Cutscene04",
		"Map04(Boss)",
		"Cutscene05"
	};

	settings.Add("sceneSplits", true, "Split on:");
	settings.Add("Map01", false, "Reaching ritual cutscene", "sceneSplits");
	settings.Add("Map02", false, "Interacting with Johnathon at the ritual", "sceneSplits");
	settings.Add("Map03", false, "Reaching Johnathon", "sceneSplits");
	settings.Add("Map04(Boss)", true, "Killing Johnathon", "sceneSplits");

	settings.Add("Cutscene01", false, "Cutscene 1 (Arrival)", "sceneSplits");
	settings.Add("Cutscene02", false, "Cutscene 2 (Sacrifice)", "sceneSplits");
	settings.Add("Cutscene03", false, "Cutscene 3 (Runaway)", "sceneSplits");
	settings.Add("Cutscene04", false, "Cutscene 4 (Boss)", "sceneSplits");
}

init
{
    var UnityPlayer = modules.FirstOrDefault(m => m.ModuleName == "UnityPlayer.dll");
	var UnityScanner = new SignatureScanner(game, UnityPlayer.BaseAddress, UnityPlayer.ModuleMemorySize);

    var RuntimeSceneManager = new SigScanTarget(2, "8B 0D ???????? 89 45 ?? 8A 45")
    { OnFound = (p, s, ptr) => p.ReadPointer(ptr) };
    vars.SceneManager = UnityScanner.Scan(RuntimeSceneManager);
	vars.BA = UnityPlayer.BaseAddress;
}

update
{
    current.LoadingScene = new DeepPointer((IntPtr)vars.SceneManager, 0x18, 0x0, 0x70).Deref<int>(game);
    current.ActiveScene = new DeepPointer((IntPtr)vars.SceneManager, 0x2C, 0x0, 0x70).Deref<int>(game);
    // current.QueueSize = new DeepPointer((IntPtr)vars.SceneManager, 0x1C).Deref<int>(game);
}

isLoading
{
    return current.ActiveScene != current.LoadingScene;
    // return current.QueueSize > 1;
}

start
{
	return old.ActiveScene == 0 &&
	       current.ActiveScene == 1;
}

split
{
	if(old.LoadingScene != current.LoadingScene) {
		print("---");
		print("" + old.LoadingScene);
		print("" + current.LoadingScene);
		print("" + settings[vars.Scenes[old.LoadingScene]]);
	}
	
	return old.LoadingScene != current.LoadingScene &&
		settings[vars.Scenes[old.LoadingScene]]
		&& current.LoadingScene != 0;
}

reset
{
	if(current.ActiveScene == null || current.LoadingScene == null) return false;
	return current.ActiveScene == 0 || current.LoadingScene == 0;
}

isLoading
{
	return current.ActiveScene != current.LoadingScene;
}

/*
 * 0 - MainMenu
 * 1 - Cutscene01
 * 2 - Map01
 * 3 - Cutscene02
 * 4 - Map02
 * 5 - Cutscene03
 * 6 - Map03
 * 7 - Cutscene04
 * 8 - Map04(Boss)
 * 9 - Cutscene05
 */