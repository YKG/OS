/* 还不明白为什么叫这么个文件名， process？ */


#include "const.h"
#include "type.h"
#include "proto.h"
#include "global.h"




u32 sys_get_ticks()
{
//	disp_color_str("+", 0x0B);

	return ticks;
}


