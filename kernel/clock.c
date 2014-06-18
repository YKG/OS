#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"


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
//			DispString("<");
//			disp_int(p->ticks);
//			DispString(">");
				greatest_ticks	= p->ticks;
				p_proc_ready	= p;
			}
		}

		if (!greatest_ticks)
		{
			for (p = proc_table; p < proc_table + NR_TASKS; p++)
			{
				 p->ticks = p->priority;				
			}
		}
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

	if (p_proc_ready->ticks > 0)
	{
		return;
	}
	

	schedule();
}



void init_clock()
{
	/* 初始化PIT */
	out_byte(TIMER_MODE, RATE_GENERATOR);			/* port: 0x43  value: 00110100 */
	out_byte(TIMER0, (u8)(TIMER_FREQ/HZ));			/* port: 0x40  低字节 */
	out_byte(TIMER0, (u8)((TIMER_FREQ/HZ) >> 8));	/* port: 0x40  高字节 */

	put_irq_handler(CLOCK_IRQ, clock_handler);
	enable_irq(CLOCK_IRQ);
}




void milli_delay(u32 milli_sec)
{
	u32 t = get_ticks();

	while ((get_ticks() - t)*1000/HZ < milli_sec)
	{
	}
}


