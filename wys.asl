state("Will You Snail", "1.3") {
    double x: "Will You Snail.exe", 0x1032200, 0x0, 0x48, 0x10, 0x5E0, 0x0;
    double chaptertime: "Will You Snail.exe", 0x10243C0, 0x8, 0x150, 0xD50;
    double fulltime: "Will You Snail.exe", 0x10243C0, 0x8, 0x150, 0xD60;
    bool showtimers: "Will You Snail.exe", 0x0101CBB8, 0x0, 0xCD0, 0x18, 0x78;
}

startup {
    vars.LevelSelect = 144;
    vars.Pause = 145;
    vars.SaveSelect = 26;
    vars.StartRoom = 29;
    vars.Frustration = 9;
    vars.Bosses = new int[] { 50, 71, 93, 121, 140, 141 };
    vars.ChapterStarts = new int[] { 29, 52, 73, 95, 123 };
    vars.ChapterEnds = new int[] { 51, 72, 94, 122, 142 };

    settings.Add("reset_onsaveselect", false, "Reset the autosplitter automatically when on the save select screen.");
    settings.Add("chapter_timer", false, "Chapter timer mode.");

    vars.OldRoomNotPause = -1;
    vars.CurrentRoomNotPause = -1;

    print("Startup complete.");
}

init { 
    print("Init start.");
    version = "1.3";

    // https://gist.github.com/just-ero/3b07dc98802ba3652cb13ff8313bbfee

    var mainModule = modules.First(); // "Will You Snail.exe"
    var scr = new SignatureScanner(game, mainModule.BaseAddress, mainModule.ModuleMemorySize);
    var levelTarget = new SigScanTarget(0xF, "3B 1D ?? ?? ?? ?? 7C E3 E8 ?? ?? ?? ?? 89 3D ?? ?? ?? ??");
 
    levelTarget.OnFound = (proc, scanner, address) => {
        var RIPaddr = proc.ReadValue<int>(address);
        return address + 0x4 + RIPaddr;
    };

    vars.room = scr.Scan(levelTarget);

    // var xPosTarget = new SigScanTarget(0x7, "85 C9 75 1D 48 8B 0D ?? ?? ?? ??");
    // xPosTarget.OnFound = (proc, scanner, address) => {
    //     var rip = proc.ReadValue<int>(address);
    //     var pointer = address + 0x4 + rip;
    //     return (IntPtr) proc.ReadValue<IntPtr>(pointer);
    // };

    // vars.x = scr.Scan(xPosTarget);
    print("Init complete.");
}

update {
   try {
        old.room = current.room;
    } catch {
        old.room = -1;
    }

    current.room = game.ReadValue<int>((IntPtr) vars.room);
    // current.x = game.ReadValue<float>((IntPtr) vars.x);

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
    // case where the unpause frames get skipped? theoretically this case shouldn't be possible
    // if(current.room == vars.LevelSelect) {
    //     int roomToCheck = old.room == vars.Pause ? vars.OldRoomNotPause : old.room;
    //     return !Array.Exists((int[]) vars.Bosses, e => e == vars.OldRoomNotPause);
    // }

    // if(current.room == vars.Pause
    //     || current.room == vars.SaveSelect || old.room == vars.SaveSelect
    //     || old.room == vars.LevelSelect
    // ) {
    //     return true;
    // }

    // return !(old.room != current.room && old.room != vars.Pause);
    // return current.room == old.room || old.fulltime == current.fulltime;
    // return true;

    return current.room == old.room && current.room == vars.SaveSelect;
}

gameTime {
    if(settings["chapter_timer"]) {
        return TimeSpan.FromSeconds(current.chaptertime);
    } else {
        return TimeSpan.FromSeconds(current.fulltime);
    }
    // if(current.room != old.room || (int) current.fulltime != (int) old.fulltime) {
    //     print("Updating. " + current.room.ToString() + " " + old.room.ToString() + " " + current.fulltime + " " + old.fulltime);
    //     return TimeSpan.FromSeconds(current.fulltime);
    // }
}

start {    
    // print(current.room.ToString() + " " + TimeSpan.FromSeconds(current.fulltime).ToString());
    if(settings["chapter_timer"]) {
        return old.room != current.room
            && current.showtimers
            && Array.Exists((int[]) vars.ChapterStarts, e => e == current.room);
    }

    return current.room == vars.StartRoom
        && current.fulltime != old.fulltime && old.fulltime == 0;
}

split {
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
        int roomToCheck = old.room == vars.Pause ? vars.OldRoomNotPause : old.room;
        return Array.Exists((int[]) vars.Bosses, e => e == vars.OldRoomNotPause);
    }

    if(current.room == vars.Pause
        || current.room == vars.SaveSelect || old.room == vars.SaveSelect
        || old.room == vars.LevelSelect
        || current.room == vars.Frustration
    ) {
        return false;
    }

    return old.room != current.room && old.room != vars.Pause;
}

reset {
	if(settings["reset_onsaveselect"] && current.room == vars.SaveSelect) {
        return true;
    }

    if(settings["chapter_timer"] && current.room == vars.LevelSelect && old.room != current.room) {
        print(vars.OldRoomNotPause.ToString());
        return !Array.Exists((int[]) vars.Bosses, e => e == vars.OldRoomNotPause);
    }
}

