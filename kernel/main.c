#include "const.h"
#include "type.h"
#include "proto.h"
#include "string.h"
#include "global.h"



void kernel_main()
{
	u32 i;

	TASK		* p_task;
	PROCESS		* p_proc;
	u16			* p_selector;
	u32			  task_stack_top;

	TASK		tasks[] = {
					{(u32)TestA, 0x8000},
					{(u32)TestB, 0x8000},
					{(u32)TestC, 0x8000},
//					{(u32)TestD, 0x8000},
					{0, 0}
				};





	disp_pos = (80*15 + 0)*2;
	DispString("======== kernel_main =========\n");


	task_stack_top	= (u32)task_stack + TASK_STACK_SIZE;
	tss.ss0			= SelectorFlatRW;

	p_task			= task_table;
	n_tasks			= 0;
	for (; tasks[n_tasks].initial_eip && tasks[n_tasks].stack_size; p_task++, n_tasks++)
	{
		p_task->initial_eip = tasks[n_tasks].initial_eip;
		p_task->stack_size  = tasks[n_tasks].stack_size;
	}
		
	for (i = 0; i < n_tasks; i++)
	{
		p_proc = &proc_table[i];
		p_proc->proc_selector = SelectorLDT + i * 0x8;		// LDT 描述符在GDT中的偏移
		init_descriptor(&gdt[i + 5], (u32)(p_proc->ldts), 2*8 - 1, DA_LDT + DA_DPL1);
		init_descriptor(&(p_proc->ldts[0]), 0, 0x0ffff, DA_C | DA_32 | DA_LIMIT_4K | DA_DPL1);	// CS
		init_descriptor(&(p_proc->ldts[1]), 0, 0x0ffff, DA_DRW| DA_32 |DA_LIMIT_4K | DA_DPL1);	// DS, ES, SS
		
		p_proc->ds	= 8 + SA_RPL1 + SA_TIL;					/* p_proc->ldts[1] + SA_RPL1 + SA_TIL */
		p_proc->es	= p_proc->ds;
		p_proc->fs	= p_proc->ds;
		p_proc->gs	= SelectorVIDEO;

		p_proc->ss	= p_proc->ds;
		task_stack_top -= task_table[i].stack_size;	/* 栈大小 stack_size */
		p_proc->esp = task_stack_top;				
		p_proc->cs	= 0 + SA_RPL1 + SA_TIL;			/* p_proc->ldts[0] */
		p_proc->eip = task_table[i].initial_eip;
		p_proc->eflags = 0x1202;					/* IOPL 1, IF 1, 第1bit总为1 ，开始没注意这个，以至于时钟中断被屏蔽了*/
	}


	k_reenter = 0;									/* 从 实验h 开始，初值为 0 */

	p_proc_ready = proc_table;

	restart();

	

//	while (1)
//	{
//	}

}






void delay() 
{
	int j, k;
	

	for (j = 0; j < 8; j++)
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
		disp_color_str("A", 0x0c);
//		DispInt(i++);

		delay();
	}
}


void TestB()
{
	int i = 0;
	
	while (1)
	{
		disp_color_str("B", 0x0c);
//		DispInt(i++);

		delay();
	}
}


void TestC()
{
	int i = 0;
	
	while (1)
	{
		disp_color_str("C", 0x0c);
//		DispInt(i++);

		delay();
	}
}


void TestD()
{
	int i = 0;
	
	while (1)
	{
		disp_color_str("D", 0x0c);
//		DispInt(i++);

		delay();
	}
}













