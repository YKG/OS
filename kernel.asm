[section .text]
global	_start
_start:
	mov	ah, 0Ch
	mov	al, 'K'
	mov	[gs:(80*3 + 15)*2], ax
	jmp	$
