state("Cuphead", "1.0")
{
	// SceneLoader#doneLoadingSceneAync
	bool doneLoading: "mono.dll", 0x20C574, 0x10, 0x1C8, 0x8, 0x3C;
}

state("Cuphead", "1.1.5")
{
	// SceneLoader#doneLoadingSceneAync
	bool doneLoading: "mono.dll", 0x20C574, 0x10, 0x1C8, 0x8, 0x3C;

	// PlayerData._CurrentSaveFileIndex
	int currentSaveFileIndex: "mono.dll", 0x20C574, 0x100, 0x1F8, 0xA4, 0x4, 0xC, 0xC;

	// PlayerData.inGame
	bool inGame: "mono.dll", 0x20C574, 0x100, 0x1F8, 0xA4, 0x4, 0xC, 0x11;
}

state("Cuphead", "1.3.2 DLC")
{
	// SceneLoader#doneLoadingSceneAync
	bool doneLoading: "UnityPlayer.dll", 0x146A608, 0x120, 0x80, 0x78;
}

startup
{	
	vars.Log = (Action<object>)(output => print("[Cuphead] " + output));

}

init
{
	var mms = modules.First().ModuleMemorySize;
	vars.Log("Init: " + mms.ToString("X"));

	switch(mms)
	{
		case 0x1244000: version = "1.0"; break;
		case 0x1245000: version = "1.1.5"; break;
		case 0xA1000: version = "1.2.4"; break;
		case 0xA4000: version = "1.3.2 DLC"; break;
		default: version = "Unknown"; break;
	}
}

isLoading
{
	return !current.doneLoading;
}