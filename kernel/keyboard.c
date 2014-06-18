#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"
#include "keyboard.h"
#include "keymap.h"


static KB_INPUT	kb_in;

void keyboard_handler(u32 irq)
{	
	u8 scan_code = in_byte(0x60);

	if (kb_in.count < KB_IN_BYTES)
	{
		*(kb_in.tail) = scan_code;
		kb_in.tail++;
		if (kb_in.tail == kb_in.buf + KB_IN_BYTES)
		{
			kb_in.tail = kb_in.buf;
		}
		kb_in.count++;
	}
}



void keyboard_read()
{	
	u8 scan_code;
	char output[2] = {0, 0};

	if (kb_in.count > 0)
	{
		disable_int();

		scan_code = *(kb_in.head);
		kb_in.head++;
		if (kb_in.head == kb_in.buf + KB_IN_BYTES)
		{
			kb_in.tail = kb_in.buf;
		}
		kb_in.count--;

		enable_int();


		if (scan_code == 0xE0)
		{
		}
		else if (scan_code == 0xE1)
		{
		}
		else
		{
			if (!(scan_code & 0x80))	/* 如果不是Break Code */
			{
				output[0] = keymap[scan_code * 3];
				disp_color_str(output, 0x0c);
//				disp_int(scan_code);
			}
		}
	}
}

void init_keyboard()
{
	kb_in.count = 0;
	kb_in.head = kb_in.tail = kb_in.buf;


	put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
	enable_irq(KEYBOARD_IRQ);
}



