org	07c00h
	mov	ax, 0b800h
	mov	es, ax
	xor	edi, edi 
	mov	edi, (80*3 + 0)*2
	xor	bx, bx 
	mov	ah, 0ch
s:
	mov	al, [MSG + bx]
	test	al, al
	jz	end
	mov	[es:edi], ax
	add	edi, 2
	inc	bx
	jmp	s
end:
	jmp	$
MSG:	db 'Hello, OS world! By YKG'
	times	510 - ($ - $$) db 0
	dw	0xaa55
