#include "const.h"
#include "type.h"
#include "proc.h"
#include "console.h"
#include "tty.h"
#include "global.h"
#include "proto.h"

void Init8259A()
{
	u32 i;

	out_byte(PORT_M_ICW1, 0x011);
	out_byte(PORT_S_ICW1, 0x011);
	out_byte(PORT_M_ICW2, 0x020);
	out_byte(PORT_S_ICW2, 0x028);
	out_byte(PORT_M_ICW3, 0x004);
	out_byte(PORT_S_ICW3, 0x002);
	out_byte(PORT_M_ICW4, 0x001);
	out_byte(PORT_S_ICW4, 0x001);

	out_byte(PORT_M_OCW1, 0xFF);	/* 11111111b  全部屏蔽 */
	out_byte(PORT_S_OCW1, 0xFF);	/* 11111111b  全部屏蔽   */

	

	for (i = 0; i < NR_IRQ; i++)
	{
		irq_table[i] = spurious_irq;
	}	
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
}





void put_irq_handler(u32 irq, void (* handler)(u32 irq))
{
	disable_irq(irq);
	irq_table[irq] = handler;
}





