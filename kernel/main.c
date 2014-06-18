#include "const.h"
#include "type.h"
#include "proto.h"
#include "string.h"
#include "global.h"




void kernel_main()
{
	DESCRIPTOR	* desc;

	disp_pos = (80*15 + 0)*2;
	DispString("======== kernel_main =========\n");


	/* 设置LDT：在GDT中增加LDT Descriptor ，序号为 4*/
	//MemCopy(ldts, &gdt[1], 3*sizeof(gdt[0]));
	init_descriptor(&gdt[4], (u32)ldts, 2*8 - 1, DA_LDT + DA_DPL1);
	init_descriptor(&ldts[0], 0, 0x0ffff, DA_C | DA_32 | DA_LIMIT_4K | DA_DPL1);	// CS
	init_descriptor(&ldts[1], 0, 0x0ffff, DA_DRW| DA_32 |DA_LIMIT_4K | DA_DPL1);	// DS, ES, SS
	/* 
	//	desc = &gdt[4];
		desc->desc_base_low			= (u16)((u32)ldts);
		desc->desc_base_mid			= (u8)(((u32)ldts)>>16);
		desc->desc_base_high		= (u8)(((u32)ldts)>>24);
		desc->desc_limit_low		= (u16)((LDT_SIZE*sizeof(ldts[0]) - 1));
		desc->desc_attr_low			= (u8)(DA_LDT);
		desc->desc_limit_attr_high	= (u8)((LDT_SIZE*sizeof(ldts[0]) - 1) << 16);
	*/
	

	DispString("ldts: ");
	DispInt((u32)ldts);
	DispString("\ngdts: ");
	DispInt((u32)gdt);
	disp_color_str("\nldts: ", 0x7F);	







	restart();


//
//	while (1)
//	{
//	}
}






void delay() 
{
	int j, k;

	for (j = 0; j < 100; j++)
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





