// unity game but no static refs and all in one scene
state("Vacation Island")
{
	// TriggerEndings instance at "mono-2.0-bdwgc.dll", 0x3A1574, 0xA8C
	bool _endingAplayed: "mono-2.0-bdwgc.dll", 0x3A1574, 0xA8C, 0x49;
	bool _endingBplayed: "mono-2.0-bdwgc.dll", 0x3A1574, 0xA8C, 0x4A;
	bool CanUsePower: "mono-2.0-bdwgc.dll", 0x3A1574, 0xA8C, 0xC, 0x78;
	bool CanHeadBob: "mono-2.0-bdwgc.dll", 0x3A1574, 0xA8C, 0xC, 0xDA;

}

startup
{
	settings.Add("split_tutorial", false, "Split on completing the tutorial.");
}

start
{
	return old.CanHeadBob && !current.CanHeadBob
	    && !current._endingAplayed && !current._endingBplayed;
}

split
{
	if (settings["split_tutorial"] && !current._endingAplayed && !current._endingBplayed
	 && old.CanUsePower && !current.CanUsePower)
	{
		return true;
	}

	return !old._endingAplayed && !old._endingBplayed
	    && (current._endingAplayed || current._endingBplayed);
}