void printf(int color, const char *string)
{
	color = 8;
	string = "This is a test";
	volatile char *video = (volatile char*)0xB8000;
	while(*string != 0)
	{
		*video++ = *string++;
		*video++ = color;
	}
}