#ifndef	_OS_TYPE_H_
#define	_OS_TYPE_H_

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


typedef	struct p_tss
{	
	u32	backlink;
	u32	esp0;	/* stack pointer to use during interrupt */
	u32	ss0;	/*   "   segment  "  "    "        "     */
	u32	esp1;
	u32	ss1;
	u32	esp2;
	u32	ss2;
	u32	cr3;
	u32	eip;
	u32	flags;
	u32	eax;
	u32	ecx;
	u32	edx;
	u32	ebx;
	u32	esp;
	u32	ebp;
	u32	esi;
	u32	edi;
	u32	es;
	u32	cs;
	u32	ss;
	u32	ds;
	u32	fs;
	u32	gs;
	u32	ldt;
	u16	trap;
	u16	iobase;	/* I/O位图基址大于或等于TSS段界限，就表示没有I/O许可位图 */
} TSS;




typedef struct s_stackframe
{
	u32	gs;
	u32	fs;
	u32	es;
	u32	ds;

	u32	edi;	/* pushad */
	u32	esi;
	u32	ebp;
	u32 kernel_esp;
	u32	ebx;
	u32	edx;
	u32	ecx;
	u32	eax;

	/*u32	error_code; *//* 发生中断时自动填充 */ /* 忘记手动越过这个地方，调了好久才发现 ——2011-7-7 19:18:58 */
	u32	retaddr;		/* 中断应该不产生error_code，不过这个位置可以放置中断处理过程中的一个返回地址 */
	u32	eip;
	u32	cs;	
	u32	eflags;
	u32	esp;
	u32 ss;
} STACK_FRAME;





typedef	struct s_proc
{	
	STACK_FRAME regs;
	u16	proc_selector;	
	DESCRIPTOR	ldts[2];
} PROCESS;



typedef	struct p_task
{
	u32	initial_eip;	
	u32	stack_size;
} TASK;



#endif
