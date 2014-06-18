#ifndef	_OS_CONST_H_
#define	_OS_CONST_H_

	#define GDT_SIZE		128
	#define IDT_SIZE		256
	#define LDT_SIZE		128


	#define	DA_386CGate		0x08C
	#define	DA_386IGate		0x08E
	#define	DA_386TGate		0x08F

	#define	DA_DPL0			0x00
	#define	DA_DPL1			0x20
	#define	DA_DPL2			0x40
	#define	DA_DPL3			0x60


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
	#define	SelectorLDT		0x020
	#define	SelectorTSS		0x028

	#define INT_VECTOR_IRQ0 0x020
	#define INT_VECTOR_IRQ1 0x028


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




#endif