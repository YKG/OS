#include "const.h"
#include "type.h"
#include "string.h"
#include "proc.h"
#include "console.h"
#include "tty.h"
#include "global.h"
#include "proto.h"

void cstart()
{	
	DispString("\n\nHello, world! By YKG\ncstart address: ");
	DispInt((u32)cstart);
	DispString("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
				"======== cstart begin =========\n");


	u16 * gdt_limit = (u16 *)(&gdt_ptr[0]);
	u32 * gdt_base  = (u32 *)(&gdt_ptr[2]);
	u16 * idt_limit = (u16 *)(&idt_ptr[0]);
	u32 * idt_base  = (u32 *)(&idt_ptr[2]);

	
	MemCopy((void *)gdt, 
			(void *)(*(u32 *)(&(gdt_ptr[2]))),
			(*(u16 *)gdt_ptr) + 1);

	*gdt_limit	= GDT_SIZE*(sizeof(DESCRIPTOR)) - 1;
	*gdt_base	= (u32)gdt;
	*idt_limit	= IDT_SIZE*(sizeof(GATE)) - 1;
	*idt_base	= (u32)idt;
	init_descriptor(&gdt[4], (u32)&tss, sizeof(TSS) - 1, DA_386TSS);


	Init_IDT();

	DispString("======== cstart end ===========\n");
}

