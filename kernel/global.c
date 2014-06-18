#include "const.h"
#include "type.h"
#include "proto.h"
#include "string.h"
#include "global.h"


irq_handler			irq_table[NR_IRQ];
sys_call_handler	sys_call_table[NR_SYS_CALL] = {sys_get_ticks};
