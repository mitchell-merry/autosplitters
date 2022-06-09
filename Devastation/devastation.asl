state("Devastation")
{
	byte isLoading: "Core.dll", 0x080B80, 0x80;
}

isLoading
{
	return current.isLoading == 1;
}