#include "const.h"
#include "type.h"
#include "string.h"
#include "proc.h"
#include "console.h"
#include "tty.h"
#include "global.h"
#include "proto.h"


irq_handler			irq_table[NR_IRQ];
sys_call_handler	sys_call_table[NR_SYS_CALL] = {sys_get_ticks};



TASK				task_table[TASK_SIZE] = {
					{(u32)task_tty, 0x8000},
					{(u32)TestA, 0x8000},
					{(u32)TestB, 0x8000},
					{(u32)TestC, 0x8000},
					{(u32)TestD, 0x8000}
					};


TTY					tty_table[NR_CONSOLES];
CONSOLE				console_table[NR_CONSOLES];



