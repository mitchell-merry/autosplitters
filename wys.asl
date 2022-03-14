state("Will You Snail") {
    int room: "Will You Snail.exe", 0xFCBA20;
    float x: "Will You Snail.exe", 0x00FC7408, 0x0;
}

startup {
    vars.LevelSelect = 144;
    vars.Pause = 145;
    vars.SaveSelect = 26;

    vars.StartRoom = 29;
    vars.Bosses = new int[] { 50, 71, 93, 121, 140, 141 };
    vars.ChapterStarts = new int[] { 52, 73, 95, 123 };

    settings.Add("reset_onsaveselect", false, "Reset the autosplitter automatically when on the save select screen.");
    settings.Add("chapter_start", false, "Start timer when entering the first level of a chapter.");

    vars.OldRoomNotPause = -1;
    vars.CurrentRoomNotPause = -1;


    // vars.Rooms = new Dictionary<int, string>();
    // vars.Rooms.Add(29, "A01");
    // vars.Rooms.Add(30, "A01.1");
    // vars.Rooms.Add(34, "A05");
    // vars.Rooms.Add(35, "A06");
}

init { 
}

update {
    if(old.room != current.room && current.room != vars.Pause) {
        vars.OldRoomNotPause = vars.CurrentRoomNotPause;
        vars.CurrentRoomNotPause = current.room;
    }

    if(old.room == current.room) {
        vars.OldRoomNotPause = vars.CurrentRoomNotPause;
    }
    
}

isLoading {
    return false;
}

start {
    if(settings["chapter_start"] // if the chapter timer is enabled
        && old.room != current.room && old.room != vars.Pause // if we entered a new room and we didn't just unpause
        && Array.Exists((int[]) vars.ChapterStarts, e => e == current.room) // if the room we entered is a chapter start
    ) {
        return true;
    }
    

    return current.room == vars.StartRoom && old.x != current.x && current.x != 544;
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