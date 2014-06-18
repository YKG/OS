[section .data]
msg:	db	'Hello, world', 0Ah

strlen	equ	$ - msg


[section .text]
global	_start
_start:
	nop
	mov	edx, strlen
	mov	ecx, msg
	mov	ebx, 1
	mov	eax, 4
	int	80h

	mov	ebx, 0
	mov	eax, 1
	int	80h
