state("TEW2")
{
	byte Chapter	: 0x3712248, 0x5C;
	bool Paused		: 0x404A896;
	bool Loading	: 0x2468028;
	float x 		: 0x39CA190;
    float y 		: 0x39CA194; 
    float z 		: 0x39CA198;
}

init
{
}

startup
{
	vars.ASLVersion = "ASL Version 1.1.6 - 06/01/23";
	
	if (timer.CurrentTimingMethod == TimingMethod.RealTime){ // stolen from dude simulator 3, basically asks the runner to set their livesplit to game time
		var timingMessage = MessageBox.Show (
			"This game uses Time without Loads (Game Time) as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (RTA).\n"+
			"Would you like to set the timing method to Game Time? This will make verification easier",
			"LiveSplit | Amok Runner",
		MessageBoxButtons.YesNo,MessageBoxIcon.Question);
		
		if (timingMessage == DialogResult.Yes){
			timer.CurrentTimingMethod = TimingMethod.GameTime;
		}
	}
	
	vars.completedSplits = new List<byte>();
	
	settings.Add(vars.ASLVersion, false);
	
	settings.Add("Chap", false, "Chapters");
	vars.Levels = new Dictionary<string,string>
	{
		{"2","Into the Flame"},
		{"3","Something Not Quite Right"},
		{"4","Resonances"},
		{"5","Behind the Curtain"},
		{"6","Lying in Wait"},
		{"7","On the Hunt"},
		{"8","Lust For Art"},
		{"9","Premiere"},
		{"10","Another Evil"},
		{"11","Hidden From the Start"},
		{"12","Reconnecting"},
		{"13","Bottomless Pit"},
		{"14","Stronghold"},
		{"15","Burning the Altar"},
		{"16","The End of This World"},
		{"17","In Limbo"},
	};
	
	 foreach (var Tag in vars.Levels)
		{
			settings.Add(Tag.Key, false, Tag.Value, "Chap");
    	};

		settings.CurrentDefaultParent = null;

	
	settings.Add("End", true, "A Way Out - Always Active");
}

update
{
	// Uncomment debug information in the event of an update.
	//print(modules.First().ModuleMemorySize.ToString());
	
	if(timer.CurrentPhase == TimerPhase.NotRunning)
	{
		vars.completedSplits.Clear();
	}
}

start
{
	return current.Chapter == 1 && old.Chapter == 0;
}

split
{
	vars.ChapStr = current.Chapter.ToString();
	
	if((settings[vars.ChapStr]) && (!vars.completedSplits.Contains(current.Chapter))){
			vars.completedSplits.Add(current.Chapter);
			return true;
		}
	
	if(current.x > 42099.80858 && current.x < 42099.80860 && current.y > -28778.58009 && current.y < -28778.58007 && current.Chapter == 17){
			return true;
	}
}

isLoading
{
	return current.Paused || current.Loading;
}

reset
{
	return current.Chapter == 1 && old.Chapter == 0;
}
