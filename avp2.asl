state("lithtech") {
    byte gameState: "d3d.ren", 0x5627C;
    string32 levelName: "object.lto", 0x2FD9B4;
    bool hasControl: "cshell.dll", 0x1C9A64, 0xD2C, 0x0;
}

startup {
    vars.InGame = 0x88;
    vars.PauseMenu = 0xA0;
    vars.MainMenu = 0xC8;
    vars.Loading = 0x98;
    vars.GameNotLoaded = 0x0;

    vars.levelsToSplitOnCutscene = new string[] { "M7S2", "P7S2", "A7S3" };
    vars.levelsToNotSplitOn = new string[] { "A_OPEN", "A4_OPEN", "M_CLOSE", "M_OPEN", "M3_OPEN", "M4_OPEN", "P_OPEN", "OUTRO" };
}

init
{
	
}

update
{ 
    
}

isLoading
{
    return current.gameState == vars.Loading; // you reckon
}

start
{
    if(current.levelName == null) return false;
    
    if(Array.IndexOf(vars.levelsToNotSplitOn, current.levelName) != -1) return false;

	return current.gameState == vars.InGame &&
            !old.hasControl && current.hasControl;
}

split
{
    if(current.levelName == null || old.levelName == null) return false;

    // specific level splits on cutscenes (split when you lose control only on these levels)
    if(old.hasControl && !current.hasControl) {
        if(Array.IndexOf(vars.levelsToSplitOnCutscene, current.levelName) != -1) return true;
    }

    // dont split on these levels
    if(Array.IndexOf(vars.levelsToNotSplitOn, current.levelName) != -1) return false;

	return old.levelName != current.levelName; // on the next level
}

reset
{
	
}