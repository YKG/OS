#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"



void clock_handler(u32 vector_no)
{	
	ticks++;

	if (k_reenter > 0)
	{
		return;
	}

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

	while ((get_ticks() - t)*1000/HZ < milli_sec)
	{
	}
}


