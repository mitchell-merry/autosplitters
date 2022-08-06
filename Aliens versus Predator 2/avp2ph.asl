state("lithtech")
{
	/*
	InGame: 0xE8
	PauseMenu: 0x3C
	MainMenu: 0x90
	Loading: 0x6C
	*/
	// byte gameState: "d3d.ren", 0x5BD14;
	/*
	InGame: 0x10
	PauseMenu: 0x64
	MainMenu: 0xB8
	Loading: 0x94
	*/
	byte gameState: "d3d.ren", 0x5C14C;
}

isLoading
{
	return current.gameState == 0x94;
}