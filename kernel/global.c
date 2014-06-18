#include "const.h"
#include "type.h"
#include "proto.h"
#include "string.h"
#include "global.h"
#include "proc.h"


irq_handler			irq_table[NR_IRQ];
sys_call_handler	sys_call_table[NR_SYS_CALL] = {sys_get_ticks};



TASK				task_table[TASK_SIZE] = {
					{(u32)TestA, 0x8000},
					{(u32)TestB, 0x8000},
					{(u32)TestC, 0x8000},
					{(u32)TestD, 0x8000}
					};



