state("Project-Win64-Shipping")
{
    long GWorld: 0x5C13008;
    // 0x5C13008 - GWorld
    // 0x30 -> PersistentLevel (Level)
    // 0xE8 -> LevelScriptActor (LevelScriptActor [MAP_World_C])
    // 0x238 -> LoadingScreenWidget (W_Loading_C)
    // 0x2F8 -> bCanClose
    bool canCloseLoadingScreen: 0x5C13008, 0x30, 0xE8, 0x238, 0x2F8;

    // 0x5C13008 - GWorld
    // 0x118 -> AuthorityGameMode (GameModeBase [ScarsGameMode])
    // 0x2C0 -> Controller (PlayerController [ScarsPlayerController])
    // 0x2B0 -> MyHUD (HUD [ScarsHud])
    // 0x830 -> CinematicWidget (HostWidget)
    // 0x289 -> is enabled
    bool cinematicEnabled: 0x5C13008, 0x118, 0x2C0, 0x2B0, 0x830, 0x289;
}

onStart
{
    // This makes sure the timer always starts at 0.00
    timer.IsGameTimePaused = true;
}

init
{
    current.inLoadingScreen = false;
}

update
{
    // whenever we change worlds we are in a loading screen first
    if (old.GWorld == 0 && old.GWorld != current.GWorld) {
        current.inLoadingScreen = true;
        print("ENTERING LOADING SCREEN.");
    }

    // if we could but now can't close the loading screen, then we just did
    // meaning we are no longer loading
    if (old.canCloseLoadingScreen && !current.canCloseLoadingScreen
     || old.cinematicEnabled && !current.cinematicEnabled
    ) {
        current.inLoadingScreen = false;
        print("LEAVING LOADING SCREEN.");
    }
}

isLoading
{
    // black loading screen (with ...)
    return current.GWorld == 0 ||
        // if we are in the loading screen, but can't close (continue) yet
        // (i.e. we are loading)
        current.inLoadingScreen && !current.canCloseLoadingScreen;
}