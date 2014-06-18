%include "pm.inc"

org	07c00h
jmp	LABEL_BEGIN

[SECTION .gdt]
GDT_DESC:	Descriptor	0, 0, 0
Code32_DESC:	Descriptor	0, Code32Len - 1, DA_C + DA_32
VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW

SelectorCode32	equ	Code32_DESC - GDT_DESC
SelectorVideo	equ	VIDEO_DESC - GDT_DESC

GdtLen	equ	$ - $$
GdtPtr	dw	GdtLen - 1
	dd	0



[SECTION .16]
[BITS	16]
LABEL_BEGIN:

xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_SEG_CODE32
mov	[Code32_DESC + 2], ax
shr	eax, 16
mov	[Code32_DESC + 4], al
mov	[Code32_DESC + 7], ah


xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, GDT_DESC
mov	dword	[GdtPtr + 2], eax

lgdt	[GdtPtr]

cli

in	al, 92h
or	al, 00000010b
out	92h, al

mov	eax, cr0
or	eax, 1
mov	cr0, eax

jmp	dword	SelectorCode32:0



[SECTION .32]
[BITS 32]
LABEL_SEG_CODE32:
mov	ax, SelectorVideo
mov	gs, ax
mov	edi, (80*12 + 79)*2
mov	ah, 0ch
mov	al, 'P'
mov	[gs:edi], ax
jmp	$

Code32Len equ	$ - $$
