state("Will You Snail", "1.3") {

    double chaptertime: "Will You Snail.exe", 0x10243C0, 0x8, 0x150, 0xD50;
    double fulltime: "Will You Snail.exe", 0x10243C0, 0x8, 0x150, 0xD60;
    bool showtimers: "Will You Snail.exe", 0x0101CBB8, 0x0, 0xCD0, 0x18, 0x78;
}

state("Will You Snail", "1.42") {
    // these need to be updated every patch
    // chaptertime is just 0x10 less on the last offset compared to fulltime
    // leveltime is like 0x20 less than chaptertime or something. it's around there. if you ever need it
    double chaptertime: "Will You Snail.exe", 0x10F40E0, 0x8, 0x170, 0xF30; 
    double fulltime: "Will You Snail.exe", 0x10F40E0, 0x8, 0x170, 0xF40;
    bool showtimers: "Will You Snail.exe", 0x010EC8D8, 0x0, 0xD50, 0x18, 0x60;
}

startup {
    vars.TimerModel = new TimerModel { CurrentState = timer };

    // update these if they change
    vars.StartupRoom = 24;
    vars.PhotosensRoom = 16;
    vars.LevelSelect = 144;
    vars.Pause = 145;
    vars.SaveSelect = 26;
    vars.StartRoom = 29;
    vars.Frustration = 9;
    vars.Bosses = new int[] { 50, 71, 93, 121, 140, 141 };
    vars.ChapterStarts = new int[] { 29, 52, 73, 95, 123 };
    vars.ChapterEnds = new int[] { 51, 72, 94, 122, 142 };

    // stolen from https://github.com/just-ero/asl/blob/main/TUNIC/TUNIC.asl
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
	{
		var mbox = MessageBox.Show(
			"\"Will You Snail?\" uses in-game time.\nWould you like to switch to it?",
			"LiveSplit | \"Will You Snail?\"",
			MessageBoxButtons.YesNo);

		if (mbox == DialogResult.Yes)
			timer.CurrentTimingMethod = TimingMethod.GameTime;
	}

    settings.Add("reset_onsaveselect", false, "Reset the autosplitter automatically when on the save select screen.");
    settings.Add("reset_ongameclose", true, "Reset the autosplitter automatically when the game closes.");
    settings.Add("chapter_timer", false, "Chapter timer mode.");

    // defaults
    vars.OldRoomNotPause = -1;
    vars.CurrentRoomNotPause = -1;

    print("Startup complete.");
}

init { 
    print("Init start.");
    
    var mms = modules.First().ModuleMemorySize;

    print(mms.ToString("X"));
    switch (mms)
    {
        case 0x142A000: version = "1.42"; break;
        case 0x1347000: version = "1.3"; break;
        default:
            version = "Unknown. Post in the discord if you need support for this version.";
            break;
    }

    // https://gist.github.com/just-ero/3b07dc98802ba3652cb13ff8313bbfee
    // i posted old screenshots in the #livesplit or #memory channel ages ago going into more depth for
    // this if you really want to get into the nitty-gritty

    var mainModule = modules.First(); // "Will You Snail.exe"
    var scr = new SignatureScanner(game, mainModule.BaseAddress, mainModule.ModuleMemorySize);
    var levelTarget = new SigScanTarget(0xF, "3B 1D ?? ?? ?? ?? 7C E3 E8 ?? ?? ?? ?? 89 3D ?? ?? ?? ??");
 
    levelTarget.OnFound = (proc, scanner, address) => {
        var RIPaddr = proc.ReadValue<int>(address);
        return address + 0x4 + RIPaddr;
    };

    vars.room = scr.Scan(levelTarget);
    
    print("Init complete. updated");
}

update {
    // have to explicitly set the values for things that are sig-scanned
    try {
        old.room = current.room;
    } catch {
        old.room = -1;
    }

    current.room = game.ReadValue<int>((IntPtr) vars.room);

    if(old.room != current.room) print(current.room.ToString());

    // handles OldRoomNotPause
    if(old.room != current.room && current.room != vars.Pause) {
        vars.OldRoomNotPause = vars.CurrentRoomNotPause;
        vars.CurrentRoomNotPause = current.room;
    }

    if(old.room == current.room) {
        vars.OldRoomNotPause = vars.CurrentRoomNotPause;
    }
    
    return true;
}

isLoading {
    // I don't know what this is doing but I don't want to touch it. Check the livesplit autosplitters documentation
    // on what isLoading does to gameTime
    return current.room == old.room && current.room == vars.SaveSelect;
}

gameTime {
    // fairly self-explanatory
    if(settings["chapter_timer"]) {
        return TimeSpan.FromSeconds(current.chaptertime);
    } else {
        return TimeSpan.FromSeconds(current.fulltime);
    }
}

start {
    // when in chapter mode:
    if(settings["chapter_timer"]) {
        return old.room != current.room     // if we just entered this room
            && current.showtimers           // and if timers are showing (so we just entered this room still, might be redundant)
            && Array.Exists((int[]) vars.ChapterStarts, e => e == current.room)     // and this room is the first room in a chapter
            && current.chaptertime < 1;     // and the timer has just reset (1 is arbitrary)
    }

    // when in full-game mode:
    return current.room == vars.StartRoom           // start only if we are in the first room (29)
        && current.fulltime != old.fulltime && old.fulltime == 0;   // and if the timer was 0 and has changed
}

split {
    // first frame
    if(old.room == -1) return false;

    // final split for chapters
    if(settings["chapter_timer"]
        && current.showtimers       // if timers are shown
        && !old.showtimers          // and they weren't shown the previous frame
        && Array.Exists((int[]) vars.ChapterEnds, e => e == current.room) // and we're at the end of a chapter
        && old.room == current.room     // and we didn't just load this room
    ) {
        return true; // split
    }

    // case where the unpause frames get skipped? theoretically this case shouldn't be possible
    if(current.room == vars.LevelSelect) {
        // if the room we were just in, not counting pause, is a boss room, and we are now in level select, split
        return Array.Exists((int[]) vars.Bosses, e => e == vars.OldRoomNotPause);
    }

    // rooms where we shouldn't split
    if(current.room == vars.Pause
        || current.room == vars.SaveSelect || old.room == vars.SaveSelect
        || old.room == vars.LevelSelect
        || current.room == vars.Frustration
        || old.room == vars.PhotosensRoom || current.room == vars.PhotosensRoom
        || old.room == vars.StartupRoom || current.room == vars.StartupRoom
    ) {
        return false;
    }

    // if we're in a new room and the old room wasn't Pause
    return old.room != current.room && old.room != vars.Pause;
}

reset {
    // self-explanatory
	if(settings["reset_onsaveselect"] && current.room == vars.SaveSelect) {
        return true;
    }

    // reset when going to level select for chapter timers. You might want to make this another setting later on
    if(settings["chapter_timer"] && current.room == vars.LevelSelect && old.room != current.room) {
        return !Array.Exists((int[]) vars.Bosses, e => e == vars.OldRoomNotPause);
    }
}

exit
{
    if(settings["reset_ongameclose"]) vars.TimerModel.Reset();
}