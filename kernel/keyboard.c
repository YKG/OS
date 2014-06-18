#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"
#include "keyboard.h"
#include "keymap.h"


static KB_INPUT	kb_in;
static int	column;
static int	make;
static int	code_with_E0;
static int	shift_l;
static int	shift_r;
static int	alt_l;
static int	alt_r;	
static int	ctrl_l;	
static int	ctrl_r;	
static u8	get_byte_from_kbuf()
{
	u8 scan_code;
	disable_int();

	while (kb_in.count <= 0)
	{
	}


	scan_code = *(kb_in.head);
	kb_in.head++;
	if (kb_in.head == kb_in.buf + KB_IN_BYTES)
	{
		kb_in.tail = kb_in.buf;
	}
	kb_in.count--;

	enable_int();
	
	return scan_code;
}


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
	u32	key;
	char output[2] = {0, 0};

	if (kb_in.count > 0)
	{
		scan_code = get_byte_from_kbuf();

		if (scan_code == 0xE1)
		{
			int i;
			u8 pausebrk_scode[] = { 0xE1, 0X1D, 0X45,
									0xE1, 0x9D, 0xC5};
			int is_pausebreak = 1;
			for (i = 1; i < 6; i++)
			{
				if (get_byte_from_kbuf() != pausebrk_scode[i])
				{
					is_pausebreak = 0;
					break;
				}
			}
			if (is_pausebreak)
			{
				key = PAUSEBREAK;
			}
		}
		else if (scan_code == 0xE0)
		{
			scan_code = get_byte_from_kbuf();

			/* PrintScreen 被按下 */
			if (scan_code == 0x2A) {
				if (get_byte_from_kbuf() == 0xE0) {
					if (get_byte_from_kbuf() == 0x37) {
						key = PRINTSCREEN;
						make = 1;
					}
				}
			}
			/* PrintScreen 被释放 */
			if (scan_code == 0xB7) {
				if (get_byte_from_kbuf() == 0xE0) {
					if (get_byte_from_kbuf() == 0xAA) {
						key = PRINTSCREEN;
						make = 0;
					}
				}
			}
			/* 不是PrintScreen, 此时scan_code为0xE0紧跟的那个值. */
			if (key == 0) {
				code_with_E0 = 1;
			}
		}


		if(key != PAUSEBREAK && key != PRINTSCREEN)
		{				
			column = 0;
			if (shift_l || shift_r)
			{
				column = 1;
			}			
			if (code_with_E0)
			{
				column = 2;
				code_with_E0 = 0;
			}			
			key = keymap[(scan_code & 0x7F) * 3 + column];

//			disp_int(key);

			make = (!(scan_code & 0x80));		/* Make Code 标志 */
			switch (key)
			{
			case SHIFT_L:
				shift_l = make;
				key = 0;
				break;
			case SHIFT_R:
				shift_r = make;
				key = 0;
				break;
			case ALT_L:
				alt_l = make;
				key = 0;
				break;
			case ALT_R:
				alt_r = make;
				key = 0;
				break;
			case CTRL_L:
				ctrl_l = make;
				key = 0;
				break;
			case CTRL_R:
				ctrl_r = make;
				key = 0;
				break;
			default:
//				disp_color_str("default", 0x07);
				if (!make)
				{
					key = 0;
				}		
				break;
			}
			
			if (key)
			{
				output[0] = key;
				disp_color_str(output, 0x0c);
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



