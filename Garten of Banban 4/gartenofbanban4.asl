state("Clay_4-Win64-Shipping")
{
    long World: 0x6684E78;
}

isLoading
{
    return current.World == 0;
}

exit
{
    timer.IsGameTimePaused = true;
}
