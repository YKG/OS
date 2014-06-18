SelectorFlatRW	equ	16
SelectorVideo	equ	24


extern disp_pos

;[section .data]
;wDispPos:	dw	0

[section .text]
global	DispString

global	disp_color_str


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
;	mov	word di, [wDispPos]
	mov	word di, [disp_pos]

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
	mov	word [disp_pos], di

	pop	edi
	pop	esi
	pop	edx
	pop	ebx
	pop	eax

	ret
;==== DispString End =========================




















































; ========================================================================
;                  void disp_color_str(char * info, int color);
; ========================================================================
disp_color_str:
	push	ebp
	mov	ebp, esp

	mov	esi, [ebp + 8]	; pszInfo
	mov	edi, [disp_pos]
	mov	ah, [ebp + 12]	; color
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah	; 是回车吗?
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

.2:
	mov	[disp_pos], edi

	pop	ebp
	ret






