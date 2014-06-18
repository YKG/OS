#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"
#include "keyboard.h"
#include "keymap.h"


static KB_INPUT	kb_in;
static int	column;
static int	make_code;
static int	code_with_E0;
static int	shift_l;
static int	shift_r;
static int	alt_l;
static int	alt_r;	
static int	ctrl_l;	
static int	ctrl_r;	

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


//		output[0] = keymap[scan_code * 3];
//		disp_int(scan_code);
//		disp_color_str(output, 0x07);

		if (scan_code == 0xE0)
		{
			code_with_E0 = 1;
		}
		else if (scan_code == 0xE1)
		{
		}
		else
		{	
			column = 0;
			make_code = 0;
			if (scan_code == 0x2A)		/* SHIFT_L Make Code */
			{
				shift_l = 1;
			}
			else if(scan_code == 0xAA)	/* SHIFT_L Break Code */
			{
				shift_l = 0;
			}			
			else if (scan_code == 0x36)		/* SHIFT_R Make Code */
			{
				shift_r = 1;
			}
			else if(scan_code == 0xb6)	/* SHIFT_R Break Code */
			{
				shift_r = 0;
			}
			else if (scan_code == 0x38)		/* ALT_L Make Code */
			{				
				if (code_with_E0)
				{
					alt_r = 1;
					code_with_E0 = 0;
				}
				else
				{
					alt_l = 1;
				}
			}
			else if(scan_code == 0xb8)	/* ALT_L Break Code */
			{
				if (code_with_E0)
				{
					alt_r = 0;
					code_with_E0 = 0;
				}
				else
				{
					alt_l = 0;
				}
			}
			else if (scan_code == 0x2C)		/* CTRL_L Make Code */
			{
				ctrl_l = 1;
			}
			else if(scan_code == 0xAC)	/* CTRL_L Break Code */
			{
				ctrl_l = 0;
			}
			else if (scan_code == 0x1D)		/* CTRL_R Make Code */
			{
				if (code_with_E0)
				{
					code_with_E0 = 0;
				}
				ctrl_r = 1;
			}
			else if(scan_code == 0x9D)	/* CTRL_R Break Code */
			{
				if (code_with_E0)
				{
					code_with_E0 = 0;
				}
				ctrl_r = 0;
			}
			else
			{
				make_code = 1;
			}
			/*
			alt_l	0x38			0xb8
			alt_r	0xe0 0x38		0xe0 0xb8
			ctrl_l	0x2c			0xac
			ctrl_r	0xe0 0x1d		0xe0 0x9d
			*/


			if (shift_l || shift_r)
			{
				column = 1;
			}


			if (make_code && !(scan_code & 0x80))	/* 如果不是Break Code */
			{
				output[0] = keymap[scan_code * 3 + column];
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



