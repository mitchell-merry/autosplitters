state("gstring")
{
    string32 activeMap:  "engine.dll", 0x64FBF1;
    string32 loadingMap: "engine.dll", 0x7C3FC5;
}

start
{
    return old.activeMap != current.activeMap && current.activeMap == "human_waste1.bsp";
}

split
{
    return old.loadingMap != current.loadingMap;
}

isLoading
{
    return current.loadingMap != current.activeMap;
}