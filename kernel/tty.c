#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"
#include "proc.h"



void task_tty()
{
	while (1)
	{
		keyboard_read();
	}
}

