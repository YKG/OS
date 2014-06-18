extern	disp_pos

[section .text]
global	DispString
global	DispInt



;==== DispString =============================
; DispString(char *str)
;=========================================
DispString:
	push	eax
	push	ebx
	push	edx
	push	esi
	push	edi
	
	mov	dword esi, [esp + 20 + 4]	; 字符串指针, 记得 eip！
	mov	dword edi, [disp_pos]

.NextChar:	
	mov	byte al, [ds:esi]
	test	al, al
	jz	.DispComplete
	cmp	al, 0Ah
	je	.DispReturn
	mov	ah, 0bh				; 青色
	mov	word [gs:di], ax
	inc	esi
	add	di, 2
	jmp	.NextChar
.DispReturn:
	; 换行
	xor	eax, eax
	xor	edx, edx
	mov	bx, 80*2
	mov	ax, di
	div	bx
	inc	ax
	mul	bx
	mov	di, ax
	inc	esi
	jmp	.NextChar

.DispComplete:
	mov	dword [disp_pos], edi

	pop	edi
	pop	esi
	pop	edx
	pop	ebx
	pop	eax

	ret
;==== DispString End =========================









;==== DispInt ================================
; DispInt(int i)
;=========================================
DispInt:
	push	eax
	push	ebx
	push	ecx
	push	esi
	push	edi
	

	mov	dword esi, [esp + 20 + 4]	; 记得 eip！
	mov	dword edi, [disp_pos]

	mov	ah, 0Bh				; 青色	
	mov	al, '0'
	mov	[gs:edi], ax
	add	edi, 2
	mov	al, 'x'
	mov	[gs:edi], ax
	add	edi, 2


	mov	ch, 8				; 8 = 32/4, 一个字符包含 4bit
	mov	cl, 32				
.next4bit:
	test	ch, ch
	jz	.DispIntComplete
	mov	ebx, esi
	sub	cl, 4
	shr	ebx, cl				; 移位操作只能使用cl寄存器或立即数
	and	bl, 00Fh
	mov	al, bl
	add	al, '0'
	cmp	bl, 10
	jb	.LowerThan10
	mov	al, bl
	sub	al, 10
	add	al, 'A'
.LowerThan10:
	mov	[gs:edi], ax
	add	edi, 2
	dec	ch
	jmp	.next4bit


.DispIntComplete:
	mov	dword [disp_pos], edi

	pop	edi
	pop	esi
	pop	ecx
	pop	ebx
	pop	eax

	ret

;==== DispInt End ============================





