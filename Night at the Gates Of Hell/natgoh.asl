// Uses mono v3 x86 which is not supported in the ASL helper library - https://github.com/just-ero/asl-help/issues/2
state("Night at the Gates of Hell")
{
	// GameManager.instance._currentGameState
	// Init, Menu, Loading, Paused, Cutscene, Conversation, Attacked, Playing, None, Shot
	int gameState: "UnityPlayer.dll", 0x14D2AEC, 0xCC, 0x34, 0x3C, 0x0, 0x3C, 0x0, 0x2C;
}

isLoading
{
	return current.gameState == 2;
}