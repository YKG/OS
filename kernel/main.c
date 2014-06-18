#include "const.h"
#include "type.h"
#include "proto.h"
#include "string.h"
#include "global.h"




void kernel_main()
{
	DESCRIPTOR	* desc;	
	PROCESS		* p_proc;
	

	disp_pos = (80*15 + 0)*2;
	DispString("======== kernel_main =========\n");

	tss.ss0	= SelectorFlatRW;

	p_proc = &proc_table[0];
	p_proc->proc_selector = SelectorLDT;	// LDT 描述符在GDT中的偏移
	init_descriptor(&gdt[4], (u32)(p_proc->ldts), 2*8 - 1, DA_LDT + DA_DPL1);
	init_descriptor(&(p_proc->ldts[0]), 0, 0x0ffff, DA_C | DA_32 | DA_LIMIT_4K | DA_DPL1);	// CS
	init_descriptor(&(p_proc->ldts[1]), 0, 0x0ffff, DA_DRW| DA_32 |DA_LIMIT_4K | DA_DPL1);	// DS, ES, SS
	
	p_proc->ds	= 8 + SA_RPL1 + SA_TIL;		/* p_proc->ldts[1] + SA_RPL1 + SA_TIL */
	p_proc->es	= p_proc->ds;
	p_proc->fs	= p_proc->ds;
	p_proc->gs	= SelectorVIDEO;

	p_proc->ss	= p_proc->ds;
	p_proc->esp = (u32)task_stack + 0x8000; /* 栈大小 0x8000 */
	p_proc->cs	= 0 + SA_RPL1 + SA_TIL;		/* p_proc->ldts[0] */
	p_proc->eip = (u32)TestA;
	p_proc->eflags = 0x1202;				/* IOPL 1, IF 1, 第1bit总为1 ，开始没注意这个，以至于时钟中断被屏蔽了*/
	

	k_reenter = -1;

	p_proc_ready = p_proc;

	restart();

	

	while (1)
	{
	}






	/* 设置LDT：在GDT中增加LDT Descriptor ，序号为 4*/
	//MemCopy(ldts, &gdt[1], 3*sizeof(gdt[0]));
//	init_descriptor(&gdt[4], (u32)ldts, 2*8 - 1, DA_LDT + DA_DPL1);
//	init_descriptor(&ldts[0], 0, 0x0ffff, DA_C | DA_32 | DA_LIMIT_4K | DA_DPL1);	// CS
//	init_descriptor(&ldts[1], 0, 0x0ffff, DA_DRW| DA_32 |DA_LIMIT_4K | DA_DPL1);	// DS, ES, SS
	/* 
	//	desc = &gdt[4];
		desc->desc_base_low			= (u16)((u32)ldts);
		desc->desc_base_mid			= (u8)(((u32)ldts)>>16);
		desc->desc_base_high		= (u8)(((u32)ldts)>>24);
		desc->desc_limit_low		= (u16)((LDT_SIZE*sizeof(ldts[0]) - 1));
		desc->desc_attr_low			= (u8)(DA_LDT);
		desc->desc_limit_attr_high	= (u8)((LDT_SIZE*sizeof(ldts[0]) - 1) << 16);
	*/
	

//	DispString("ldts: ");
//	DispInt((u32)ldts);
//	DispString("\ngdts: ");
//	DispInt((u32)gdt);
////	disp_color_str("\nldts: ", 0x7F);	
//
//
//
//
//
//	k_reenter = -1;
//
//	restart();
//
//
//
//	while (1)
//	{
//	}
}






void delay() 
{
	int j, k;

	for (j = 0; j < 40; j++)
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
		disp_color_str(" A ", 0x0c);
		DispInt(i++);

		delay();
	}

}





