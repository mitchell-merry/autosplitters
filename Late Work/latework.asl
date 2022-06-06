state("Late Work")
{
    byte isPaused: "UnityPlayer.dll", 0x012BDAB0, 0x24, 0xF0;
    byte isLoading: "UnityPlayer.dll", 0x12C4848, 0x20;
}

init { }

start
{
    if(current.isLoading == 0 && old.isLoading == 1 && current.isPaused == 0) {
        return true;
    }
}

reset { 
    
}

split 
{ 
    if(current.isPaused == 1 && old.isPaused == 0) {
        return true;
    }
}