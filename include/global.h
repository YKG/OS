#ifndef	_OS_GLOBAL_VAR_H_
#define	_OS_GOLBAL_VAR_H_
#endif

u32			disp_pos;
u32			keyboardint_count;
u8			gdt_ptr[6];
u8			idt_ptr[6];
DESCRIPTOR	gdt[GDT_SIZE];
GATE		idt[IDT_SIZE];


TSS			tss;

u32			k_reenter;	/* 处理中断重入 */

u32			n_tasks;
extern		TASK		task_table[];
extern		u32			NR_TASKS;
PROCESS		proc_table[PROC_SIZE];
PROCESS		* p_proc_ready;

u32			task_stack[TASK_STACK_SIZE];


extern		irq_handler			irq_table[];
extern		sys_call_handler	sys_call_table[];

u32			ticks;


