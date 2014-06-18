#ifndef	_OS_GLOBAL_VAR_H_
#define	_OS_GOLBAL_VAR_H_

u32			disp_pos;
u32			keyboardint_count;
u8			gdt_ptr[6];
u8			idt_ptr[6];
DESCRIPTOR	gdt[GDT_SIZE];
GATE		idt[IDT_SIZE];



DESCRIPTOR	ldts[LDT_SIZE];


TSS			tss;

#endif
