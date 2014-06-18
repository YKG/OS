#define GDT_SIZE		128
#define IDT_SIZE		256

#define	DA_386CGate		0x8C
#define	DA_386IGate		0x8E
#define	DA_386TGate		0x8F

#define	DA_DPL0			0x0
#define	DA_DPL1			0x1
#define	DA_DPL2			0x2
#define	DA_DPL3			0x3

#define	SelectorFlatC	0x8




typedef	unsigned char	u8;
typedef	unsigned short	u16;
typedef	unsigned int	u32;

typedef	struct p_descriptor
{
	u16	desc_limit_low;
	u16	desc_base_low;
	u8	desc_base_mid;
	u8	desc_attr_low;
	u8	desc_limit_attr_high; /* limit low 4bit   attr high 4bit*/
	u8	desc_base_high;
} DESCRIPTOR;


typedef	struct p_gate
{
	u16	gate_offset_low;
	u16	gate_selector;
	u8	gate_attr_low;
	u8	gate_attr_high;
	u16	gate_offset_high;
} GATE;





u32			disp_pos;
u8			gdt_ptr[6];
u8			idt_ptr[6];
DESCRIPTOR	gdt[GDT_SIZE];
GATE		idt[IDT_SIZE];


void * MemCopy(void *dest, void *src, int size);
void DispString();
void Init_IDT_DESC(u8 vec_no, u8 type, void * handler, u8 privilege);
void Init_IDT();
void divide_error();
void debug_exception();
void nmi ();
void overflow_exception();
void breakpoint_exception();
void bound_exception();
void undefine_opcode_exception();
void no_match_coprocessor_exception();
void double_fault_exception();
void coprocessor_segment_overrun_exception();
void invalid_tSS_exception();
void segment_not_present_exception();
void stack_segment_sault_exception();
void general_protection_exception();
void page_fault_exception();
void reserved_exception();
void math_fault_exception();
void alignment_check_exception();
void machine_check_exception();
void smid_floating_point_exception();



void cstart()
{	
	u16 * gdt_limit = (u16 *)(&gdt_ptr[0]);
	u32 * gdt_base  = (u32 *)(&gdt_ptr[2]);
	u16 * idt_limit = (u16 *)(&idt_ptr[0]);
	u32 * idt_base  = (u32 *)(&idt_ptr[2]);

	
	MemCopy((void *)gdt, 
			(void *)(*(u32 *)(&(gdt_ptr[2]))),
			(*(u16 *)gdt_ptr) + 1);

	*gdt_limit = GDT_SIZE*(sizeof(DESCRIPTOR)) - 1;
	*gdt_base  = (u32)gdt;
	*idt_limit = IDT_SIZE*(sizeof(GATE)) - 1;
	*idt_base  = (u32)idt;
	

	DispString("\n\nHello, world! By YKG\n");
	DispInt(1);
	DispString("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
				"======== cstart =========\n");

	DispInt(divide_error);
	DispString("  ");
	DispInt(Init_IDT);


	Init_IDT();
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


	DispString("vec_no:   ");
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
}



void Init_IDT_DESC(u8 vec_no, u8 type, void * handler, u8 privilege)
{
	GATE *gate;

	gate = &idt[vec_no];
	gate->gate_offset_low	= (u16)((u32)handler);
	gate->gate_selector		= SelectorFlatC;	/* CS */
	gate->gate_attr_low		= privilege;
	gate->gate_attr_high	= type;				/* 0x8E 中断门 */
	gate->gate_offset_high	= (u16)((u32)handler >> 16);
}


void Init_IDT()
{
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
}












