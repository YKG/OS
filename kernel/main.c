#include "const.h"
#include "type.h"
#include "proto.h"
#include "string.h"
#include "global.h"


void kernel_main()
{
	u32 i;

	PROCESS		* p_proc;
	u16			* p_selector;
	u32			  task_stack_top;

	ticks = 0;
	disp_pos = (80*15 + 0)*2;
	DispString("======== kernel_main =========\n");


	task_stack_top	= (u32)task_stack + TASK_STACK_SIZE;
	tss.ss0			= SelectorFlatRW;
	for (i = 0; i < NR_TASKS; i++)
	{
		p_proc = &proc_table[i];
		p_proc->proc_selector = SelectorLDT + i * 0x8;		// LDT 描述符在GDT中的偏移
		init_descriptor(&gdt[i + 5], (u32)(p_proc->ldts), 2*8 - 1, DA_LDT + DA_DPL1);
		init_descriptor(&(p_proc->ldts[0]), 0, 0x0ffff, DA_C | DA_32 | DA_LIMIT_4K | DA_DPL1);	// CS
		init_descriptor(&(p_proc->ldts[1]), 0, 0x0ffff, DA_DRW| DA_32 |DA_LIMIT_4K | DA_DPL1);	// DS, ES, SS
		
		p_proc->regs.ds	= 8 + SA_RPL1 + SA_TIL;					/* p_proc->ldts[1] + SA_RPL1 + SA_TIL */
		p_proc->regs.es	= p_proc->regs.ds;
		p_proc->regs.fs	= p_proc->regs.ds;
		p_proc->regs.gs	= SelectorVIDEO;

		p_proc->regs.ss	= p_proc->regs.ds;
		task_stack_top -= task_table[i].stack_size;	/* 栈大小 stack_size */
		p_proc->regs.esp = task_stack_top;				
		p_proc->regs.cs	= 0 + SA_RPL1 + SA_TIL;			/* p_proc->ldts[0] */
		p_proc->regs.eip = task_table[i].initial_eip;
		p_proc->regs.eflags = 0x1202;					/* IOPL 1, IF 1, 第1bit总为1 ，开始没注意这个，以至于时钟中断被屏蔽了*/
	}

	
	/* 设置优先级 */
	proc_table[0].ticks = proc_table[0].priority = 15;
	proc_table[1].ticks = proc_table[1].priority = 5;
	proc_table[2].ticks = proc_table[2].priority = 3;






	k_reenter = 0;									/* 从 实验h 开始，初值为 0 */
	p_proc_ready = proc_table;


	/* 清屏 */
	disp_pos = 0;
	for (i = 0; i < (80 * 25); i++)
	{
		disp_color_str(" ", 0x07);
	}
	disp_pos = 0;



	/* 初始化PIT */
	out_byte(TIMER_MODE, RATE_GENERATOR);			/* port: 0x43  value: 00110100 */
	out_byte(TIMER0, (u8)(TIMER_FREQ/HZ));			/* port: 0x40  低字节 */
	out_byte(TIMER0, (u8)((TIMER_FREQ/HZ) >> 8));	/* port: 0x40  高字节 */

	put_irq_handler(CLOCK_IRQ, clock_handler);
	enable_irq(CLOCK_IRQ);

	restart();

	while (1)
	{
		disp_int(8);
	}
}




void delay() 
{
	int j, k;
	
	for (j = 0; j < 80; j++)
	{
		for (k = 0; k < 10000; k++)
		{			
		}
	}
}

void TestA()
{
	int i = 0;
	
	while (1)
	{		
		disp_color_str(" A", 0x0c);
//		disp_int(proc_table[0].ticks);

		milli_delay(10);
	}
}


void TestB()
{
	int i = 0x1000;
	
	while (1)
	{
		disp_color_str(" B", 0x0E);
//		disp_int(proc_table[1].ticks);
	
		milli_delay(10);
	}
}


void TestC()
{
	int i = 0x2000;
	
	while (1)
	{		
		disp_color_str(" C", 0x0A);
//		disp_int(proc_table[2].ticks);

		milli_delay(10);
	}
}


void TestD()
{
	int i = 0;
	
	while (1)
	{
		disp_color_str("D", 0x0B);
//		DispInt(i++);

		delay();
	}
}













