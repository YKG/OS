#ifndef	_OS_PROTO_H_
#define	_OS_PROTO_H_
#endif

void DispString(char *str);
void disp_color_str(char *str, u8 color);
void DispInt(u32 i);
void disp_int(u32 i);

void init_descriptor(DESCRIPTOR *desc, u32 base, u32 limit, u16 attr);
void Init_IDT_DESC(u8 vec_no, u8 type, void * handler, u8 privilege);
void Init_IDT();
void Init8259A();
void divide_error();
void debug_exception();
void nmi();
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

void hwint00();
void hwint01();
void hwint02();
void hwint03();
void hwint04();
void hwint05();
void hwint06();
void hwint07();
void hwint08();
void hwint09();
void hwint10();
void hwint11();
void hwint12();
void hwint13();
void hwint14();
void hwint15();

void sys_call();

//void hwinterupt();
void enable_irq(u32 irq);
void disable_irq(u32 irq);
void spurious_irq(u32 vector_no);
void clock_handler(u32 vector_no);
void put_irq_handler(u32 irq, irq_handler handler);


void restart();
void delay();
void TestA();
void TestB();
void TestC();
void TestD();

u32 sys_get_ticks();
u32 get_ticks();
void milli_delay(u32 milli_sec);
void keyboard_handler(u32 vector_no);
void keyboard_read();
void init_keyboard();
void init_clock();


void disable_int();
void enable_int();
void task_tty();
void in_process(TTY *p_tty, u32 key);


