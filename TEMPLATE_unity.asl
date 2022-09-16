state("In Sound Mind")
{
	bool isLoading : "unityplayer.dll", 0x19fb7c8, 0x78;
	long inventoryUI: "UnityPlayer.dll", 0x01952CC0, 0x330, 0x48, 0x168, 0x30, 0x30, 0x18, 0x28;
}

startup
{
	var bytes = File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin");
	var type = Assembly.Load(bytes).GetType("ASLHelper.Unity");
	vars.Helper = Activator.CreateInstance(type, timer, this);
	// vars.Helper.LoadSceneManager = true;
	
	vars.Log = (Action<object>)(output => print("[] " + output));
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });

	vars.Helper.AlertLoadless("");
}

init
{
	vars.Helper.TryOnLoad = (Func<dynamic, bool>)(mono =>
	{
		return true;
	});

	vars.Helper.Load();
}

update
{
	if (!vars.Helper.Update())
		return false;
}

exit
{
	vars.Helper.Dispose();
}

shutdown
{
	vars.Helper.Dispose();
}