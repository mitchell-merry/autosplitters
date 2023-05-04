state("hitman3")
{
    bool isLoading: "hitman3.exe", 0x39B0F6C;
}

isLoading
{
    return current.isLoading;
}