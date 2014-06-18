#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"


/*

void schedule()
{
	u32 i;
	u32 greatest_ticks = 0;
	u32 x;


	while (!greatest_ticks)
	{
		for (i = 0; i < NR_TASKS; i++)
		{
			if (greatest_ticks	< (proc_table + i)->ticks)
			{
//		disp_int(i);
//		disp_color_str(": ", 0x0F);


//		DispString("<");
//		disp_int(i);
//		DispString(",");
//		disp_int((proc_table + i)->ticks);
//		DispString(">");
				greatest_ticks	= (proc_table + i)->ticks;
				p_proc_ready	= proc_table + i;
				x = i;
			}
		}

//		disp_color_str(" _", 0x0F);
//		disp_int(x);
//		disp_color_str("_ ", 0x0F);

		if (0)//!greatest_ticks)
		{
			for (i = 0; i < NR_TASKS; i++)
			{
				proc_table[i].ticks = proc_table[i].priority;
			}
		}
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
*/



void schedule()
{
	PROCESS * p;
//	u32 i;
//	u32 greatest_ticks = 0;
//	u32 x;
	int i = 0;
	int greatest_ticks = 0;

	
	
	while (!greatest_ticks)
	{
//		disp_int(greatest_ticks);
//		DispString("w");
		for (p = proc_table; p < proc_table + NR_TASKS; p++)
		{
//			DispString("f");
			if (greatest_ticks	< p->ticks)
			{
//		disp_int(i);
//		disp_color_str(": ", 0x0F);


//		DispString("<");
////		disp_int(p - proc_table);
////		DispString(",");
//		disp_int(p->ticks);
//		DispString(">");
				greatest_ticks	= p->ticks;
				p_proc_ready	= p;
//				x = i;
			}
		}

//		DispString("@");
//		disp_int(p_proc_ready - proc_table);
//		DispString("@");


//		disp_color_str(" _", 0x0F);
//		disp_int(x);
//		disp_color_str("_ ", 0x0F);

		if (!greatest_ticks)
		{
			for (i = 0; i < NR_TASKS; i++)
			{
				proc_table[i].ticks = proc_table[i].priority;
			}
		}
	}

/*
 气死我了！这个没注释掉！以至于调了几个小时啊。。。。。。。。。。。。
****************************************************

	if (p_proc_ready < &proc_table[NR_TASKS - 1])
	{
		p_proc_ready++;
	}
	else
	{
		p_proc_ready = proc_table;
	}
*/
}



void clock_handler(u32 vector_no)
{	
//	disp_color_str("#", 0x07);
//	disp_int(ticks);
	ticks++;
	p_proc_ready->ticks--;

//	disp_int(proc_table->ticks);
//	disp_int((proc_table + 1)->ticks);
//	disp_int((proc_table + 2)->ticks);


	if (k_reenter != 0)
	{
//		disp_color_str("!", 0x0E);
		return;
	}
//	disp_int(ticks);
	schedule();
}




void milli_delay(u32 milli_sec)
{
	u32 t = get_ticks();

	while ((get_ticks() - t)*1000/HZ < milli_sec)
	{
	}
}


