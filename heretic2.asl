state("Heretic2")
{
    // both are good candidates
    bool isLoading: "quake2.dll", 0x76A588;
    // bool isLoading: "quake2.dll", 0x76A5A0;

    string128 scene: "quake2.dll", 0x841B4;
}

startup
{
    // vars.LevelLabels = new Dictionary<string, string>()
    // {
    //     {"ssdocks", "Silverspring Docks"},
    //     {"sswarehouse", "Silverspring Warehouse"},
    //     {"sstown", "The Town of Silverspring"},
    //     {"sspalace", "Silverspring Palace"},
    //     {"", "Darkmire Swamps"},
    //     {"andhealer", "Andoria Healer's Tower"},
    //     {"andplaza", "Andoria Plaza"},
    //     {"andacademic", "Andoria Academic Quarters"},
    //     {"andslums", "Andoria Slums"},
    //     {"kellcaves", "Kell Caves"},
    //     {"canyon", "Katlit'k Canyon"},
    //     {"hive1", "K'Chekrik Hive 1"},
    //     {"hive2", "K'Chekrik Hive 2"},
    //     {"gauntlet", "The Gauntlet"},
    //     {"hivetrialpit", "The Trial Pit"},
    //     {"", "Lair of the Mothers"},
    //     {"oglemine1", "Ogle Mines 1"},
    //     {"oglemine2", "Ogle Mines 2"},
    //     {"dungeon", "Morcalavin's Dungeon"},
    //     {"", "Cloud Fortress"},
    //     {"", "Morcalavin's Inner Sanctum"},
    //     {"cloudlabs", "Cloud Fortress Labs"},
    //     {"cloudquarters", "Cloud Living Quarters"},
    // };

    vars.Cutscenes = new List<string>() { "intro.smk" };
    vars.StartScenes = new List<string>() { "tutorial", "ssdocks" };
}

update
{
    if(old.scene != current.scene)
    {
        print("Scene: " + old.scene + " -> " + current.scene);
    }

    if(old.isLoading != current.isLoading)
    {
        print("isLoading: " + old.isLoading + " -> " + current.isLoading);
    }
}

isLoading
{
    return current.isLoading;
}

start
{
    return old.isLoading && !current.isLoading          // start after a load
        && vars.StartScenes.Contains(current.scene);    // if we are loading into a start scene
}

split
{
    return old.scene != current.scene                   // changing scenes
        && !vars.Cutscenes.Contains(old.scene);         // and we didnt change from a cutscene
}