state("HITMAN3", "Steam")
{
    bool isLoading: "hitman3.exe", 0x39B0F6C;
}

state("HITMAN3", "Epic")
{
    bool isLoading: 0x14E4BC, 0xB0;
}

init
{
    string MD5Hash;
    var md5 = System.Security.Cryptography.MD5.Create();
    var s = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
    MD5Hash = md5.ComputeHash(s).Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
    print("Hash is: " + MD5Hash);

    switch (MD5Hash){
        case "A6BCD7BA2587B589764FE00EF6942F7A": version = "Steam"; break;
        case "Epic Hash Here": version = "Epic"; break;

        default: version = "UNKNOWN"; break;
    }

    print("Chose version " + version);
}

isLoading
{
    return current.isLoading;
}