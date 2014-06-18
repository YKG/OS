SelectorFlatC	equ	8


extern	cstart
extern	gdt_ptr


[section .bss]
resb	2*1024
TopOfStack:


[section .text]
global	_start

_start:
	mov	esp, TopOfStack

	sgdt	[gdt_ptr]
	call	cstart
	lgdt	[gdt_ptr]
	
	jmp	SelectorFlatC:csinit

csinit:
	xor	eax, eax
	push	eax
	popfd

	hlt









