时钟中断处理部分涉及TSS的部分处理的不好，已作修订，
参考 kernel/kernel.asm 第 267 - 291 行

		————— 2011-7-8 13:15:42







现在添加进程更简单：
	0. 在 /include/proto.h 中声明
	1. 在 /kernel/main.c 中增加一个函数 TestXXX()
	3. 在 /kernel/main.c::kernel_main() 中的tasks数组里面在{0, 0}之前增加这行：
		{(u32)TestXXX, 栈大小},
	4. make
	5. make buildimg
	

		———— 2011-7-7 23:19:03




