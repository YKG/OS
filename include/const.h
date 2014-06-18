#ifndef	_OS_CONST_H_
#define	_OS_CONST_H_

	#define GDT_SIZE		128
	#define IDT_SIZE		256
	#define LDT_SIZE		128
	#define TASK_SIZE		128
	#define PROC_SIZE		128
	#define	TASK_STACK_SIZE	0x50000


	#define	DA_386CGate		0x08C
	#define	DA_386IGate		0x08E
	#define	DA_386TGate		0x08F

	#define	DA_DPL0			0x00
	#define	DA_DPL1			0x20
	#define	DA_DPL2			0x40
	#define	DA_DPL3			0x60

	#define	SA_RPL0			0x00
	#define	SA_RPL1			0x01
	#define	SA_RPL2			0x02
	#define	SA_RPL3			0x03



	#define	DA_32			0x4000
	#define	DA_LIMIT_4K		0x8000
	#define	DA_C			0x98
	#define	DA_DRW			0x92


	#define	DA_LDT			0x82
	#define	DA_386TSS		0x89

	#define	SA_TIL			0x04

	#define	SelectorFlatC	0x008
	#define	SelectorFlatRW	0x010
	#define	SelectorVIDEO	0x018
	#define	SelectorTSS		0x020
	#define	SelectorLDT		0x028


	#define INT_VECTOR_IRQ0 0x020
	#define INT_VECTOR_IRQ1 0x028
	#define	CLOCK_IRQ		0		
	#define KEYBOARD_IRQ	1
	


	#define	PORT_M_ICW1		0x020
	#define	PORT_S_ICW1		0x0A0
	#define	PORT_M_ICW2		0x021
	#define	PORT_S_ICW2		0x0A1
	#define	PORT_M_ICW3		0x021
	#define	PORT_S_ICW3		0x0A1
	#define	PORT_M_ICW4		0x021
	#define	PORT_S_ICW4		0x0A1
	#define	PORT_M_OCW1		0x021
	#define	PORT_S_OCW1		0x0A1

	/* 时钟 定时器 */
	#define	TIMER_MODE		0x43
	#define	RATE_GENERATOR	0x34		/* 00110100b */
	#define	TIMER0			0x40
	#define	TIMER_FREQ		1193182L	/* 输入频率 */
	#define	HZ				100			/* 每10ms产生一次中断, 每秒 100 ticks */
	
	/* VGA */
	#define	CRTC_ADDR_REG	0x3D4	/* CRT Controller Registers - Addr Register */
	#define	CRTC_DATA_REG	0x3D5	/* CRT Controller Registers - Data Register */
	#define	START_ADDR_H	0xC	/* reg index of video mem start addr (MSB) */
	#define	START_ADDR_L	0xD	/* reg index of video mem start addr (LSB) */
	#define	CURSOR_H	0xE	/* reg index of cursor position (MSB) */
	#define	CURSOR_L	0xF	/* reg index of cursor position (LSB) */
	#define	V_MEM_BASE	0xB8000	/* base of color video memory */
	#define	V_MEM_SIZE	0x8000	/* 32K: B8000H -> BFFFFH */


	

	#define	NR_IRQ			16
	#define	NR_SYS_CALL		10


	#define	NR_CONSOLES		3

#endif
