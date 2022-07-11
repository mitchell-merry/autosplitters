state("Cuphead", "1.0")
{
	bool doneLoading: "mono.dll", 0x1F40AC, 0xCC, 0x3C;
	// other candidates
	// bool doneLoading: "mono.dll", 0x1F40AC, 0xCC, 0x8, 0x18, 0x3C;
	// bool doneLoading: "mono.dll", 0x20C574, 0x10, 0x1C8, 0x8, 0x3C;
	// bool doneLoading: "mono.dll", 0x20CAE4, 0x10, 0x1C8, 0x8, 0x3C;
	// bool doneLoading: "mono.dll", 0x1F62CC, 0x54, 0x1C8, 0x8, 0x3C;
	// bool doneLoading: "mono.dll", 0x1F62F0, 0x54, 0x1C8, 0x8, 0x3C;
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