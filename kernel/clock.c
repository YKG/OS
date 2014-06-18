#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"



void schedule()
{
	PROCESS * p;
	int greatest_ticks = 0;
	
	while (!greatest_ticks)
	{
		for (p = proc_table; p < proc_table + NR_TASKS; p++)
		{
			if (greatest_ticks	< p->ticks)
			{
			DispString("<");
			disp_int(p->ticks);
			DispString(">");
				greatest_ticks	= p->ticks;
				p_proc_ready	= p;
			}
		}
		
		/*
		if (!greatest_ticks)
		{
			for (p = proc_table; p < proc_table + NR_TASKS; p++)
			{
				 p->ticks = p->priority;				
			}
		}
		*/
	}

	
}



void clock_handler(u32 vector_no)
{	
	ticks++;
	p_proc_ready->ticks--;

	if (k_reenter != 0)
	{
		return;
	}

	schedule();
}




void milli_delay(u32 milli_sec)
{
	u32 t = get_ticks();

	while ((get_ticks() - t)*1000/HZ < milli_sec)
	{
	}
}


