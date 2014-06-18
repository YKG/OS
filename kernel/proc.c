/* 还不明白为什么叫这么个文件名， process？ */


#include "const.h"
#include "type.h"
#include "proc.h"
#include "console.h"
#include "tty.h"
#include "global.h"
#include "proto.h"


u32 sys_get_ticks()
{
//	disp_color_str("+", 0x0B);

	return ticks;
}


