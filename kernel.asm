SelectorFlatC	equ	8
SelectorFlatRW	equ	16
SelectorVideo	equ	24

extern	cstart
extern	gdt_ptr


[section .data]
wDispPos:	dw	0


[section .bss]
resb	2*1024
TopOfStack:



[section .text]
global	_start
global	MemCopy
global	DispString

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
	mov	ax, SelectorFlatRW
	mov	ds, ax
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
	mov	word di, [wDispPos]

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
	mov	word [wDispPos], di

	pop	edi
	pop	esi
	pop	edx
	pop	ebx
	pop	eax

	ret
;==== DispString End =========================

