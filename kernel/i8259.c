#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"


void Init8259A()
{
		out_byte(PORT_M_ICW1, 0x011);
		out_byte(PORT_S_ICW1, 0x011);
		out_byte(PORT_M_ICW2, 0x020);
		out_byte(PORT_S_ICW2, 0x028);
		out_byte(PORT_M_ICW3, 0x004);
		out_byte(PORT_S_ICW3, 0x002);
		out_byte(PORT_M_ICW4, 0x001);
		out_byte(PORT_S_ICW4, 0x001);
	
		out_byte(PORT_M_OCW1, 0xFE);	/* 11111110b  开时钟中断 */
		out_byte(PORT_S_OCW1, 0xFF);	/* 11111111b  全部屏蔽   */

}



void spurious_irq(u32 vector_no)
{
	disp_pos = (80*0 + 60)*2;		/* 第10行 */
	DispString("INT:     ");
	DispInt(vector_no); 
	disp_pos = (80*1 + 60)*2;
	DispString("count:   ");
	DispInt(keyboardint_count); 
	DispString("\n");

	keyboardint_count++;			/* 为啥不更新呢。。! 因为之前没发送 EOI, 外加硬件中断使用 ret 返回了，应该是 iretd */

	out_byte(PORT_M_ICW1, 0x20);	/* 发送 EOI, port: 0x20, value: 0x20 */
}



void clock_handler(u32 vector_no)
{	
	disp_color_str("$", 0x0b);

	if (k_reenter > 0)
	{
		disp_color_str("!", 0x0C);
		return;
	}

/*	delay(); */

	if (p_proc_ready < &proc_table[n_tasks - 1])
	{
		p_proc_ready++;
	}
	else
	{
		p_proc_ready = proc_table;
	}
}

