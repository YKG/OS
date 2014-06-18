#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"
#include "keyboard.h"


void task_tty()
{
	while (1)
	{
		keyboard_read();
	}
}


void in_process(u32 key)
{
	char output[2] = {0, 0};
	
	if (!(key & FLAG_EXT))
	{
		output[0] = key;
		disp_color_str(output, 0x0c);
	}
}

