state("TEW2") {
    string128 spinnerTypeString: 0x1F17A90, 0x30, 0xA28, 0x0, 0x14;
    int spinnerType: 0x1F17A90, 0x30, 0xA28, 0x0, 0x2C;
    int loadingPercentage: 0x1F17A90, 0x30, 0xA28, 0x0, 0x30;

    // I constructed this by stepping through the assembly and working my way up
    // this is *not* randomly scanned
    bool isPaused: 0x1F17A90, 0x28, 0x0, 0x80, 0x1C8, 0x18, 0x8, 0x8, 0xC;
    // this is nulled out on initial de-load
    long isPausedParent: 0x1F17A90, 0x28;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "The Evil Within 2";
}

init
{
    /**
     * enum GameState {
     *   STATE_PRESS_START = 0,
     *   STATE_USER_SETUP = 1,
     *   STATE_INITIAL_SCREEN = 2, // main menu
     *   STATE_PARTY_LOBBY_HOST = 3,
     *   STATE_PARTY_LOBBY_PEER = 4,
     *   STATE_PARTY_LOBBY_HOST = 5, // happens during load
     *   STATE_PARTY_LOBBY_PEER = 6,
     *   STATE_CREATE_AND_MOVE_TO_PARTY_LOBBY = 7,
     *   STATE_CREATE_AND_MOVE_TO_GAME_LOBBY = 8, // happens during load
     *   STATE_FIND_OR_CREATE_MATCH = 9,
     *   STATE_CONNECT_AND_MOVE_TO_PARTY = 10,
     *   STATE_CONNECT_AND_MOVE_TO_GAME = 11,
     *   STATE_BUSY = 12,
     *   STATE_LOADING = 13, // main load
     *   STATE_INGAME = 14, 
     * }
     */
    vars.gameStateBaseScan = vars.Helper.ScanRel(3, "48 8b 0d ?? ?? ?? ?? 48 8b 01 ff 50 30 83 F8 07 0F 85 ?? ?? ?? ??");
}
          

update
{
    current.gameState = vars.Helper.Read<int>(vars.gameStateBaseScan, 0x8);

    if (!((IDictionary<string, object>)(old)).ContainsKey("gameState")) {
        vars.Log("Loaded values:");
        vars.Log("  gameState: " + current.gameState + " [at " + (vars.Helper.Read<long>(vars.gameStateBaseScan) + 0x8).ToString("X") + "]");
        vars.Log("  isPaused: " + current.isPaused);
        vars.Log("  isPausedParent: " + current.isPausedParent.ToString("X"));
        vars.Log("  spinner type: '" + current.spinnerTypeString + "' [" + current.spinnerType + "]");
        return;
    }

    if (old.gameState != current.gameState) {
        vars.Log("gameState: " + old.gameState + " -> " + current.gameState);
    }

    if (old.isPaused != current.isPaused) {
        vars.Log("isPaused: " + old.isPaused + " -> " + current.isPaused);
    }

    if (old.isPausedParent != current.isPausedParent) {
        vars.Log("isPausedParent: " + old.isPausedParent.ToString("X") + " -> " + current.isPausedParent);
    }

    if (old.spinnerTypeString != current.spinnerTypeString || old.spinnerType != current.spinnerType) {
        vars.Log("spinner type: '" + old.spinnerTypeString + "' [" + old.spinnerType + "], '"  + current.spinnerTypeString + "' [" + current.spinnerType + "]");
    }
}

isLoading
{
    return current.spinnerType == 3 // spinner is loading_area (monitor / computer warps)
        || current.isPaused        // self-explanatory!
        || current.isPausedParent == 0 // used for loading from a pause menu, since it is deleted when the level unloads (which causes isPaused to be 0 due to ZeroOrNull)
        || current.gameState == 13 // STATE_LOADING
        || current.gameState == 5  // STATE_PARTY_LOBBY_HOST
        || current.gameState == 8; // STATE_CREATE_AND_MOVE_TO_GAME_LOBBY
}
