#include "const.h"
#include "type.h"
#include "proc.h"
#include "keyboard.h"
#include "console.h"
#include "tty.h"
#include "global.h"
#include "proto.h"

//TTY					tty_table[NR_CONSOLES];
//CONSOLE				console_table[NR_CONSOLES];


static void set_cursor(unsigned int position)
{
	disable_int();
	out_byte(CRTC_ADDR_REG, CURSOR_H);
	out_byte(CRTC_DATA_REG, (position >> 8) & 0xFF);
	out_byte(CRTC_ADDR_REG, CURSOR_L);
	out_byte(CRTC_DATA_REG, position & 0xFF);
	enable_int();
}


int is_current_console(CONSOLE* p_con)
{
	return (p_con == &console_table[nr_current_console]);
}


void out_char(CONSOLE* p_con, char ch)
{
	u8* p_vmem = (u8*)(V_MEM_BASE + disp_pos);

//	disp_int(disp_pos);

	*p_vmem++ = ch;
	*p_vmem++ = 0x0c; //DEFAULT_CHAR_COLOR;
	disp_pos += 2;

//	set_cursor(disp_pos/2);
	set_cursor(disp_pos/2);
}



