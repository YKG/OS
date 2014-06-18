[section .text]
global	MemCopy


;==== MemCopy ================================
; MemCopy(char *dest, char *src, int size)
;=========================================
MemCopy:
	push	edi
	push	esi
	push	ecx
	push	eax
	
	mov	edi, [esp + 16 + 4]	; 目的地址，因为栈中还有个 eip
	mov	esi, [esp + 24]		; 源地址
	mov	ecx, [esp + 28]		; 长度
.nextbyte:
	mov	al, [ds:esi]
	mov	[ds:edi], al
	inc	esi
	inc	edi
	loop	.nextbyte

	pop	eax
	pop	ecx
	pop	esi
	pop	edi

	ret
;==== MemCopy End ============================
