extern sys_call_table


[section .text]
global	get_ticks

get_ticks:
xchg	bx, bx
;	mov	eax, sys_call_table
;	mov	eax, [sys_call_table]
	mov	eax, 0
	int	0x90
	ret


