state("Night at the Gates of Hell")
{
	int gameState: "UnityPlayer.dll", 0x14D2AEC, 0xCC, 0x34, 0x3C, 0x0, 0x3C, 0x0, 0x2C;
}

isLoading
{
	return current.gameState == 2;
}