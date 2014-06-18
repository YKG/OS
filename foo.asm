extern	choose

[section .data]
msg:	db	'Hello, world', 0Ah

strlen	equ	$ - msg

num1	dd	011111111h
num2	dd	022222222h


[section .text]
global	_start
global	myprint	

_start:
	nop


	push	dword [num2]
	push	dword [num1]
	call	choose
	add	esp, 8

	mov	ebx, 0
	mov	eax, 1
	int	80h

myprint:	
	mov	edx, [esp + 8]
	mov	ecx, [esp + 4]
	mov	ebx, 1
	mov	eax, 4
	int	80h
	ret

