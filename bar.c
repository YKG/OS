void myprint(char *msg, int len);

int choose(int a, int b)
{
	if(a >= b)
	{
		myprint("a>=b\n", 5);
	}
	else
	{
		myprint("a<b\n", 4);
	}
	return 0;
}
