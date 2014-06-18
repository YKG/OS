#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"



void clock_handler(u32 vector_no)
{	
	disp_color_str("$", 0x0b);
	ticks++;

	if (k_reenter > 0)
	{
		disp_color_str("!", 0x0C);
		return;
	}

/*	delay(); */

	if (p_proc_ready < &proc_table[NR_TASKS - 1])
	{
		p_proc_ready++;
	}
	else
	{
		p_proc_ready = proc_table;
	}
}




