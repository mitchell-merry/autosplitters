state("Will You Snail", "1.3") {
    double fulltime: "Will You Snail.exe", 0x10243C0, 0x8, 0x150, 0xD60;
}

startup {
    vars.LevelSelect = 144;
    vars.Pause = 145;
    vars.SaveSelect = 26;
    vars.StartRoom = 29;
    vars.Frustration = 9;
    vars.Bosses = new int[] { 50, 71, 93, 121, 140, 141 };
    vars.ChapterStarts = new int[] { 52, 73, 95, 123 };

    settings.Add("reset_onsaveselect", false, "Reset the autosplitter automatically when on the save select screen.");

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

    var xPosTarget = new SigScanTarget(0x7, "85 C9 75 1D 48 8B 0D ?? ?? ?? ??");
    xPosTarget.OnFound = (proc, scanner, address) => {
        var rip = proc.ReadValue<int>(address);
        var pointer = address + 0x4 + rip;
        return (IntPtr) proc.ReadValue<IntPtr>(pointer);
    };

    vars.x = scr.Scan(xPosTarget);
    print("Init complete.");
}

update {
   try {
        old.room = current.room;
    } catch {
        old.room = -1;
    }

    current.room = game.ReadValue<int>((IntPtr) vars.room);
    current.x = game.ReadValue<float>((IntPtr) vars.x);

    if(old.room != current.room && current.room != vars.Pause) {
        vars.OldRoomNotPause = vars.CurrentRoomNotPause;
        vars.CurrentRoomNotPause = current.room;
    }

    if(old.room == current.room) {
        vars.OldRoomNotPause = vars.CurrentRoomNotPause;
    }
    
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
    return current.room == vars.SaveSelect;
}

gameTime {
    return TimeSpan.FromSeconds(current.fulltime);
}

start {    
    print(current.room.ToString() + " " + TimeSpan.FromSeconds(current.fulltime).ToString());
    return current.room == vars.StartRoom
        && current.fulltime != old.fulltime && old.fulltime == 0;
}

split {
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
	if(settings["reset_onsaveselect"]) {
        return current.room == vars.SaveSelect;
    }
}