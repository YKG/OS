#include "const.h"
#include "type.h"
#include "proc.h"
#include "console.h"
#include "tty.h"
#include "global.h"
#include "proto.h"


void Init_IDT_DESC(u8 vec_no, u8 type, void * handler, u8 privilege)
{
	GATE *gate;

	gate = &idt[vec_no];
	gate->gate_offset_low	= (u16)((u32)handler);
	gate->gate_selector		= SelectorFlatC;	/* CS */
	gate->gate_attr_low		= 0;				/* 此实验之前的都是错的！ */
	gate->gate_attr_high	= type | privilege;	/* 0x8E 中断门 */
	gate->gate_offset_high	= (u16)((u32)handler >> 16);
}



void init_descriptor(DESCRIPTOR *desc, u32 base, u32 limit, u16 attr)
{
	desc->desc_limit_low		= (u16)(limit);
	desc->desc_base_low			= (u16)(base);
	desc->desc_base_mid			= (u8)(base>>16);
	desc->desc_attr_low			= (u8)(attr);
	desc->desc_limit_attr_high	= (u8)(limit>>16 | attr>>8);
	desc->desc_base_high		= (u8)(base>>24);
}



void Init_IDT()
{
	Init8259A();

	Init_IDT_DESC(0x00, DA_386IGate,				      divide_error    , DA_DPL0);
	Init_IDT_DESC(0x01, DA_386IGate,				       debug_exception, DA_DPL0);
	Init_IDT_DESC(0x02, DA_386IGate,				         nmi          , DA_DPL0);
	Init_IDT_DESC(0x03, DA_386IGate,				    overflow_exception, DA_DPL0);
	Init_IDT_DESC(0x04, DA_386IGate,				  breakpoint_exception, DA_DPL0);
	Init_IDT_DESC(0x05, DA_386IGate,                       bound_exception, DA_DPL0);
	Init_IDT_DESC(0x06, DA_386IGate,             undefine_opcode_exception, DA_DPL0);
	Init_IDT_DESC(0x07, DA_386IGate,        no_match_coprocessor_exception, DA_DPL0);
	Init_IDT_DESC(0x08, DA_386IGate,                double_fault_exception, DA_DPL0);
	Init_IDT_DESC(0x09, DA_386IGate, coprocessor_segment_overrun_exception, DA_DPL0);
	Init_IDT_DESC(0x0a, DA_386IGate,                 invalid_tSS_exception, DA_DPL0);
	Init_IDT_DESC(0x0b, DA_386IGate,		 segment_not_present_exception, DA_DPL0);
	Init_IDT_DESC(0x0c, DA_386IGate,		 stack_segment_sault_exception, DA_DPL0);
	Init_IDT_DESC(0x0d, DA_386IGate,		  general_protection_exception, DA_DPL0);
	Init_IDT_DESC(0x0e, DA_386IGate,		          page_fault_exception, DA_DPL0);
	Init_IDT_DESC(0x0f, DA_386IGate,		            reserved_exception, DA_DPL0);
	Init_IDT_DESC(0x10, DA_386IGate,		          math_fault_exception, DA_DPL0);
	Init_IDT_DESC(0x11, DA_386IGate,		     alignment_check_exception, DA_DPL0);
	Init_IDT_DESC(0x12, DA_386IGate,		       machine_check_exception, DA_DPL0);
	Init_IDT_DESC(0x13, DA_386IGate,		 smid_floating_point_exception, DA_DPL0);


	Init_IDT_DESC(INT_VECTOR_IRQ0 + 0, DA_386IGate, hwint00, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ0 + 1, DA_386IGate, hwint01, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ0 + 2, DA_386IGate, hwint02, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ0 + 3, DA_386IGate, hwint03, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ0 + 4, DA_386IGate, hwint04, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ0 + 5, DA_386IGate, hwint05, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ0 + 6, DA_386IGate, hwint06, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ0 + 7, DA_386IGate, hwint07, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 0, DA_386IGate, hwint08, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 1, DA_386IGate, hwint09, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 2, DA_386IGate, hwint10, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 3, DA_386IGate, hwint11, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 4, DA_386IGate, hwint12, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 5, DA_386IGate, hwint13, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 6, DA_386IGate, hwint14, DA_DPL0);
	Init_IDT_DESC(INT_VECTOR_IRQ1 + 7, DA_386IGate, hwint15, DA_DPL0);



	Init_IDT_DESC(0x90, DA_386IGate, sys_call, DA_DPL3);
}







void exception_handler(u32 vec_no, u32 err_code, u32 eip, u32 cs, u32 eflags)
{
	int i;	

	char *msg[] = {
		"#DE Divide Error",
		"#DB RESERVED",
		"--  NMI Interrupt",
		"#BP Breakpoint",
		"#OF Overflow",
		"#BR BOUND Range Exceeded",
		"#UD Invalid Opcode (Undefined Opcode)",
		"#NM Device Not Available (No Math Coprocessor)",
		"#DF Double Fault",
		"    Coprocessor Segment Overrun (reserved)",
		"#TS Invalid TSS",
		"#NP Segment Not Present",
		"#SS Stack-Segment Fault",
		"#GP General Protection",
		"#PF Page Fault",
		"--  (Intel reserved. Do not use.)",
		"#MF x87 FPU Floating-Point Error (Math Fault)",
		"#AC Alignment Check",
		"#MC Machine Check",
		"#XF SIMD Floating-Point Exception"		
	};
		
	/* 清理屏幕前 5 行 */	
	disp_pos = 0;
	for (i = 0; i < 80*5; i++)
	{
		DispString(" ");
	}
	disp_pos = 0;

/*
//	DispString("vec_no:   ");
	DispInt(vec_no);
	DispString("  ");
    DispString(msg[vec_no]);
	DispString("\nerr_code: ");
	DispInt(err_code);
	DispString("\neip:      ");
	DispInt(eip);
	DispString("\ncs:       ");
	DispInt(cs);
	DispString("\neflags:   ");
	DispInt(eflags);
*/
	disp_color_str("vec_no:   ", 0x7F);
	DispInt(vec_no);
	DispString("  ");
    DispString(msg[vec_no]);
	disp_color_str("\nerr_code: ", 0x7F);
	DispInt(err_code);
	disp_color_str("\neip:      ", 0x7F);
	DispInt(eip);
	disp_color_str("\ncs:       ", 0x7F);
	DispInt(cs);
	disp_color_str("\neflags:   ", 0x7F);
	DispInt(eflags);

}




