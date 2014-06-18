org	7c00h
mov	ax, 0b800h
mov	es, ax
mov	edi, (80*10 + 79)*2
mov	ah, 0ch
mov	al, 'P'
s:
mov	[es:edi], ax
jmp	s

times	510 - ($ - $$)	db	0
dw	0aa55h
