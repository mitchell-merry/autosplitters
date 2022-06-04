/// <reference path="./asr.d.ts">

let current, old;

/** cutscenes in-game, do not split on these */
const cutscenes = [ "intro.smk", "outro.smk" ];
/** scenes which the timer should start on */
const startScenes = [ "tutorial", "ssdocks" ];

/** mapping of scene ids to names */
const sceneName = {
    "ssdocks": "Silverspring Docks",
    // ... etc
}

/** the game's process */
let process;
/** main module */
let quake2dll;

/** isLoading - boolean (byte) */
const isLoadingOffset = 0x76A588;
/** scene - string (32 bytes max) */
const sceneOffset = 0x841B4;

function update() {
    try {
    
    if(process === null) {
        try {
            process = new Process("Heretic2.exe");
            quake2dll = process.getModuleAddress("quake2.dll");
            if(!quake2dll) return;
        } catch { return; }
    }

    // I don't know what happens to process after detach
    if(!process.isOpen()) {
        process.detach();
        return;
    }

    // I like the current/old pattern
    old = Object.fromEntries(Object.entries(current));

    current.isLoading = new Uint8Array(process.read(quake2dll + isLoadingOffset, 1))[0];
    current.scene = new Uint8Array(process.read(quake2dll + sceneOffset, 32)).toString();

    Timer.setVariable("Level / Scene", sceneName[current.scene]);

    switch(Timer.getState()) {
        case TimerState.NotRunning:
            if(start()) Timer.start();
            break;
        case TimerState.Running:
            if(isLoading()) Timer.pauseGameTime();
            if(split()) Timer.split();
            break;
        case TimerState.Paused:
            if(!isLoading()) Timer.resumeGameTime();
            break;
        case TimerState.Ended:
            // do nothing i guess
            break;
    }

    } catch(e) {
        printMessage(e);
    }
}

function start() {
    return !current.isLoading && old.isLoading
        && startScenes.includes(current.scene);
}

function split() {
    return old.scene !== current.scene
        && old.scene !== "" && current.scene !== ""
        && !cutscenes.includes(old.scene);
}

function isLoading() {
    return current.isLoading;
}