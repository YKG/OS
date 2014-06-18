#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"
#include "keyboard.h"


void task_tty()
{
	while (1)
	{
		keyboard_read();
	}
}


void in_process(u32 key)
{
	char output[2] = {0, 0};
	
	if (!(key & FLAG_EXT))
	{
//		DispString("tty: ");
//		disp_int(key);
//		DispString(" ");
//		disp_int(FLAG_EXT);
//		DispString(" ");
//		disp_int(key & FLAG_EXT);
//		DispString(" ");
//		disp_int(!(key & FLAG_EXT));

		output[0] = key;
		disp_color_str(output, 0x0c);

		disable_int();
		out_byte(CRTC_ADDR_REG, CURSOR_H);
		out_byte(CRTC_DATA_REG, ((disp_pos/2)>>8)&0xFF);
		out_byte(CRTC_ADDR_REG, CURSOR_L);
		out_byte(CRTC_DATA_REG, (disp_pos/2)&0xFF);
		enable_int();
	}
	else
	{
//		DispString("tty2: ");
//		disp_int(key);
//		DispString(" ");
//		disp_int(FLAG_EXT);
//		DispString(" ");
//		disp_int(key & FLAG_EXT);
//		DispString(" ");
//		disp_int(!(key & FLAG_EXT));
//		DispString(" ");
//		disp_int(MASK_RAW);

		int raw_code = key & MASK_RAW;

//		DispString(" raw: ");
//		disp_int(raw_code);		
//		DispString(" up: ");
//		disp_int(UP);
//		DispString(" down: ");
//		disp_int(DOWN);


		switch(raw_code) {
		case UP:
				if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R)) {
						disable_int();
						out_byte(CRTC_ADDR_REG, START_ADDR_H);
						out_byte(CRTC_DATA_REG, ((80*15) >> 8) & 0xFF);
						out_byte(CRTC_ADDR_REG, START_ADDR_L);
						out_byte(CRTC_DATA_REG, (80*15) & 0xFF);
						enable_int();
				}
				break;
		case DOWN:
				if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R)) {
					/* 回到第一页 */
						disable_int();
						out_byte(CRTC_ADDR_REG, START_ADDR_H);
						out_byte(CRTC_DATA_REG, ((80*0) >> 8) & 0xFF);
						out_byte(CRTC_ADDR_REG, START_ADDR_L);
						out_byte(CRTC_DATA_REG, (80*0) & 0xFF);
						enable_int();
				}
				break;
		default:
				break;
		}
	}
}

