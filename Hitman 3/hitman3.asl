// how to find the values & what they mean are in the README.md file
state("HITMAN3", "Epic August 2023")
{
    bool isLoading: 0x398A229;
}

state("HITMAN3", "Steam August 2023")
{
    bool isLoading: 0x39B220C;
    bool isInMainMenu: 0x31A6AB4;
    bool hasControl: 0x3174E48;
    bool inCutscene: 0x33A53CC;
}

state("HITMAN3", "Game Pass May 2023")
{
    bool isLoading: 0x3AA4BFC;
}

startup
{
    // we want to make sure the user is using the load remover
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var mbox = MessageBox.Show(
            "HITMAN 3 Freelancer uses load-removed time.\nWould you like to switch to it?",
            "LiveSplit | HITMAN 3 Freelancer",
            MessageBoxButtons.YesNo);

        if (mbox == DialogResult.Yes)
            timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
}

init
{
    var mms = modules.First().ModuleMemorySize.ToString("X");
    print("MMS is: " + mms);

    // MMS as a workaround to the Game Pass not working (#4)
    switch (mms) {
        case "4A67000": version = "Epic August 2023"; break;
        case "4A71000": version = "Steam August 2023"; break;
        case "4ABE000": version = "Game Pass May 2023"; break;

        default: version = "UNKNOWN - raise an issue on GitHub if you want support for this version"; break;
    }

    print("Chose version " + version);

    // assume we are not in the intro cutscene on init
    // this does technically mean if the timer is opened and started during the intro cutscene, it will falsely pause
    // but this doesn't actually matter at all
    vars.inIntroCutscene = false;
}

update
{
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
        || ((current.inCutscene || !current.hasControl) && !vars.inIntroCutscene);
}
