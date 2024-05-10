// how to find the values & what they mean are in the README.md file
state("HITMAN3") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "HITMAN 3 Freelancer";
    vars.Helper.AlertGameTime();
}

init
{
    // in short, each of these signatures match one section in the assembly that contain a reference to the
    // memory address we want to find. we scan that signature, once we find it we add the 0x5 or whatever offset
    // from the beginning of the signature to get the address
    // some magic behind the scenes converts that from a relative address to an absolute one
    // find this by looking at what instructions write to your addresses, then work backwards to find where the address
    // comes from with cheat engine's stack trace
    vars.isLoadingScan = vars.Helper.ScanRel(0x5, "75 13 48 8B 05 ?? ?? ?? ?? 48 8D 0D ?? ?? ?? ?? B2 01");
    vars.isInMainMenuScan = vars.Helper.ScanRel(0xA, "48 89 35 ?? ?? ?? ?? 48 8D 0D ?? ?? ?? ?? 40 88 35");
    vars.inCutsceneScan = vars.Helper.ScanRel(0xB, "88 44 24 ?? E8 ?? ?? ?? ?? FF 0D");
    vars.hasControlScan = vars.Helper.ScanRel(0x9, "4C 8B C0 49 C1 E8 ?? C6 05 ?? ?? ?? ?? 01");
    vars.usingCameraScan = vars.Helper.ScanRel(0x6, "48 8B CB 48 89 1D ?? ?? ?? ?? EB 16 48 39 1D");

    // assume we are not in the intro cutscene on init
    // this does technically mean if the timer is opened and started during the intro cutscene, it will falsely pause
    // but this doesn't actually matter at all
    vars.inIntroCutscene = false;
}

update
{
    // read new values
    current.isLoading = vars.Helper.Read<bool>(vars.isLoadingScan + 0x3C);
    current.isInMainMenu = vars.Helper.Read<bool>(vars.isInMainMenuScan + 0x194);
    current.inCutscene = vars.Helper.Read<bool>(vars.inCutsceneScan);
    current.hasControl = vars.Helper.Read<bool>(vars.hasControlScan + 0x1);
    current.usingCamera = vars.Helper.Read<bool>(vars.usingCameraScan + 0x4);

    // if we have just loaded in, we are in an intro cutscene
    // (or the main menu, which is paused regardless anyway)
    if (old.isLoading && !current.isLoading) {
        vars.inIntroCutscene = true;
    }

    // if we were in the intro cutscene, but we have gained control, then the cutscene is over
    if (vars.inIntroCutscene && !old.hasControl && current.hasControl) {
        vars.inIntroCutscene = false;
    }
}

isLoading
{
    return current.isLoading    // if we are in a loading screen...
        || current.isInMainMenu // or we're in the main menu...
        // or we're in a cutscene or don't have control and we're not currently in the intro cutscene (to the safehouse or the level)
        || (!vars.inIntroCutscene && (
            current.inCutscene || (
                // hasControl is false while using the camera, but time should still be running
                !current.hasControl && !current.usingCamera
            )
        ));
}
