state("nocturne")
{
	bool isLoading    : "nocturne.exe", 0x18C316C;
	string128 map     : "nocturne.exe", 0x1BA3F8C;
	bool inGame       : "nocturne.exe", 0x18AE0D4;
	bool inGameOrStart: "nocturne.exe", 0x29FC25C, 0xDE3;
}

startup
{
	#region Debugging
	// should always be false publicly
	vars.DEBUG = true;

	vars.Log = (Action<object>)(output => print("[Nocturne] " + output.ToString()));
	// https://stackoverflow.com/questions/26778554/why-cant-i-index-into-an-expandoobject
	vars.ExpandoIndex = (Func<dynamic, string, dynamic>)((eo, key) => ((IDictionary<string, dynamic>)eo)[key]);
	
	#region FileLogging
	if (vars.DEBUG)
	{
		var desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
		var path = Path.Combine(desktop, "LOG_Nocturne_diggity.txt");
		vars.Writer = new StreamWriter(path, append: true);
		vars.Writer.AutoFlush = true;
		vars.Writer.WriteLine("--RELOADING LIVESPLIT--");
	}

	vars.LogAndWrite = (Action<object>)(output => 
	{
		vars.Log(output);

		if (vars.DEBUG) 
		{
			var gt = !timer.CurrentTime.GameTime.HasValue ? "        "
			     : timer.CurrentTime.GameTime.Value.ToString(@"mm\:ss\.ff");
			
			vars.Writer.WriteLine(String.Format("[{0}] [{1}] [{2}] [{3}] {4}",
				DateTime.Now, timer.Run.AttemptCount,
				timer.CurrentTime.RealTime.Value.ToString(@"mm\:ss\.ff"),
				gt,
				output
			));
		}
	});
	#endregion FileLogging

	// current is the same as old in init, so need to have those passed in unfortunately
	// need a better way to do this
	// watches to see if current.<key> != old.<key>, and if so log the change. common pattern
	vars.WatchValue = (Action<dynamic, dynamic, string>)((curr, ol, key) => 
	{
		var c = vars.ExpandoIndex(curr, key);
		var o = vars.ExpandoIndex(ol, key);
		if (c != o) vars.LogAndWrite(String.Format("{0}: {1} -> {2}", key, o, c));
	});

	vars.WatchValues = (Action<dynamic, dynamic, List<string>>)((curr, ol, keys) =>
	{
		foreach(var key in keys) vars.WatchValue(curr, ol, key);
	});

	vars.ValuesToWatch = new List<string> { "isLoading", "inGame", "inGameOrStart", "map" };
	#endregion Debugging

	vars.CompletedSplits = new List<string>();
	vars.Vol1Chapters = new List<string> { "HQ.geo", "GTOWN.geo", "FOREST.geo", "CASTLE.geo", "DUNGEON.geo" };
}

init
{ }

update
{
	if (vars.DEBUG) vars.WatchValues(current, old, vars.ValuesToWatch);
}

start
{
	// loading into first map from main menu (so out of game)
	if (current.isLoading && current.map == "HQ.geo" && current.inGame
	    && (current.inGame != old.inGame || current.map != old.map))
	{
		if (vars.DEBUG) vars.LogAndWrite(String.Format("STARTING | isLoading: {0} | map: {1} | inGame {2} -> {3}", current.isLoading, current.map, old.inGame, current.inGame));
		
		return true;
	}
}

onStart
{
	vars.CompletedSplits.Clear();
}

split
{
	if (current.map != old.map
	    && !vars.CompletedSplits.Contains(current.map))
	{
		if (vars.DEBUG) vars.LogAndWrite(String.Format("SPLITTING | map: {0} -> {1}", old.map, current.map));
		
		vars.CompletedSplits.Add(current.map);
		return true;
	}
}

isLoading
{
	// https://discord.com/channels/144133978759233536/144134231201808385/727009875569279048
	if (current.isLoading && timer.CurrentTime.GameTime.HasValue
	   && timer.CurrentTime.RealTime.Value < TimeSpan.FromMilliseconds(30))
	{
		vars.LogAndWrite("Overwrite Game Time to 0");
		timer.SetGameTime(TimeSpan.Zero);
	}

	return current.isLoading;
}

shutdown
{
	if (vars.DEBUG) vars.Writer.Close();
}