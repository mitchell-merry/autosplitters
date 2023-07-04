state("HITMAN3", "Epic May 2023")
{
    bool isLoading: 0x398A029;
}

state("HITMAN3", "Steam May 2023")
{
    bool isLoading: 0x39B220C;
}

state("HITMAN3", "Game Pass May 2023")
{
    bool isLoading: 0x3AA4BFC;
}

startup
{
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
        case "4A67000": version = "Epic May 2023"; break;
        case "4A71000": version = "Steam May 2023"; break;
        case "4ABE000": version = "Game Pass May 2023"; break;

        default: version = "UNKNOWN - raise an issue on GitHub if you want support for this version"; break;
    }

    print("Chose version " + version);
}

isLoading
{
    return current.isLoading;
}