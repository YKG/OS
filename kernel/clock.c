#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"



void clock_handler(u32 vector_no)
{	
//	disp_color_str("#", 0x07);
	ticks++;

	if (k_reenter > 0)
	{
//		disp_color_str("!", 0x07);
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




void milli_delay(u32 milli_sec)
{
	u32 t = get_ticks();

//	disp_int(t);
//	disp_color_str("  ", 0x00);
	
	while ((get_ticks() - t)*1000/HZ < milli_sec)
	{
	}
//	disp_int(get_ticks());
}


