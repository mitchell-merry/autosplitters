state("HITMAN3", "Steam")
{
    bool isLoading: 0x39B220C;
}

state("HITMAN3", "Epic")
{
    bool isLoading: 0x14D530, 0xFEC;
}

state("HITMAN3", "Game Pass")
{
    bool isLoading: 0x3AA4BFC;
}

init
{
    var mms = modules.First().ModuleMemorySize.ToString("X");
    print("MMS is: " + mms);

    // MMS as a workaround to the Game Pass not working (#4)
    switch (mms) {
        case "4A67000": version = "Epic"; break;
        case "4A71000": version = "Steam"; break;
        case "4ABE000": version = "Game Pass"; break;

        default: version = "UNKNOWN - raise an issue on GitHub if you want support for this version"; break;
    }

    print("Chose version " + version);
}

isLoading
{
    return current.isLoading;
}