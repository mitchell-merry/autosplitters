state("ArcRunner-Win64-Shipping")
{
    long GWorld: 0x4F82630;
    // 0x4F82630 - GWorld
    // 0x180 - OwningGameInstance (GameInstance [BP_GameInstance_C])
    // 0x4C0 - CurrentLevel
    int level: 0x4F82630, 0x180, 0x4C0;
}

isLoading
{
    return current.GWorld == 0;
}

split
{
    return current.level > old.level;
}