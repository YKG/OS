#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"


void keyboard_handler(u32 vector_no)
{	
	DispString("*");
}


void init_keyboard()
{
	put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
	enable_irq(KEYBOARD_IRQ);
}



