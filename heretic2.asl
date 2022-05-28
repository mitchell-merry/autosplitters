state("Heretic2")
{
    // both are good candidates
    bool isLoading: "quake2.dll", 0x76A588;
    // bool isLoading: "quake2.dll", 0x76A5A0;
}

isLoading
{
    return current.isLoading;
}