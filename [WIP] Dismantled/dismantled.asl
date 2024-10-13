// Dismantled uses lzdoom version 3.82
// source code of the engine: https://github.com/drfrag666/gzdoom/tree/3.82

state("lzdoom") {
    // the mother of everything is `level`, it is a struct at lzdoom.exe+9F5B78, I think
    // the part we care about begins at lzdoom.exe+9F5DE8 (everything before would be FLevelData members)
    // find it's address by dissecting the G_DoCompleted() function and finding when level.time, level.maptime, and level.totaltime are set to 0,
    // and correspond that to assembly
    
    // level.time (+0x280, this is a struct so no pointer deref)
    // you can figure out the rest from here
    // int time: "lzdoom.exe", 0x9F5DF8;
    // int maptime: "lzdoom.exe", 0x9F5DFC;
    string128 MapName: "lzdoom.exe", 0x9F5E38, 0x0;

    // this is a global
    int gameaction: "lzdoom.exe", 0x7044E0, 0x0;

    // players.[0]->mo->__Pos.X/Y
    double posX: "lzdoom.exe", 0x7043C0, 0x0, 0x48;
    double posY: "lzdoom.exe", 0x7043C0, 0x0, 0x50;
}

isLoading
{
    return current.gameaction == 14;
}

start
{
    return current.MapName == "MAP01"
        && current.posX == -22371 && current.posY == 12672
        && old.gameaction == 14 && current.gameaction == 0;
}

/**
enum gameaction_t : int
{
	ga_nothing,
	ga_loadlevel,
	ga_newgame,
	ga_newgame2,
	ga_recordgame,
	ga_loadgame,
	ga_loadgamehidecon,
	ga_loadgameplaydemo,
	ga_autoloadgame,
	ga_savegame,
	ga_autosave,
	ga_playdemo,
	ga_completed,
	ga_slideshow,
	ga_worlddone,
	ga_screenshot,
	ga_togglemap,
	ga_fullconsole,
	ga_resumeconversation,
};

*/

// startup
// {
//     // if you die and reload a save, you don't lose any time for that
//     // we should make it so by tracking our own total time that persists between saves
//     vars.TotalTime = 0;

//     vars.MapStartTime = 0;
// }

// update
// {
//     var TICRATE = 35;
//     if (old.MapName != current.MapName)
//     {
//         print("before: " + vars.TotalTime + ", " + vars.MapStartTime + "(" + ((float) (vars.TotalTime + (current.time - vars.MapStartTime)) / TICRATE) + ")");
//         vars.TotalTime += (current.time - vars.MapStartTime);
//         vars.MapStartTime = current.time;
//         print("after: " + vars.TotalTime + ", " + vars.MapStartTime + "(" + ((float) (vars.TotalTime + (current.time - vars.MapStartTime)) / TICRATE) + ")");
//     }
// }

// onStart
// {
//     vars.TotalTime = 0;
//     vars.MapStartTime = current.time;
// }

// gameTime
// {
//     var TICRATE = 35;
//     // return TimeSpan.FromSeconds((float) (vars.TotalTime + (current.time - vars.MapStartTime)) / TICRATE);
//     return TimeSpan.FromSeconds((float) current.time / TICRATE);
// }