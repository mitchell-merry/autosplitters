state("HITMAN3", "Steam")
{
    bool isLoading: 0x39B220C;
}

state("HITMAN3", "Epic")
{
    bool isLoading: 0x14D530, 0xFEC;
}

init
{
    string MD5Hash;
    var md5 = System.Security.Cryptography.MD5.Create();
    var s = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
    MD5Hash = md5.ComputeHash(s).Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
    print("Hash is: " + MD5Hash);

    switch (MD5Hash){
        case "81F5EC2450D4369583D28495445311F6": version = "Steam"; break;
        case "F9B0347F278B533ACE9A744B5B5353F9": version = "Epic"; break;

        default: version = "UNKNOWN"; break;
    }

    print("Chose version " + version);
}

isLoading
{
    return current.isLoading;
}