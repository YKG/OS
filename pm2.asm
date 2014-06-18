%include "pm.inc"

org	0100h
xchg	bx, bx
jmp	LABEL_BEGIN

[SECTION .gdt]
GDT_DESC:	Descriptor	0, 0, 0
Code32_DESC:	Descriptor	0, Code32Len - 1, DA_C + DA_32
;Code16_DESC:	Descriptor	0, Code16Len - 1, DA_C
Code16_DESC:	Descriptor	0, 0ffffh, DA_C
VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW
Normal_DESC:	Descriptor	0, 0ffffh, DA_DRW

SelectorCode32	equ	Code32_DESC - GDT_DESC
SelectorCode16	equ	Code16_DESC - GDT_DESC
SelectorVideo	equ	VIDEO_DESC - GDT_DESC
SelectorNormal	equ	Normal_DESC - GDT_DESC

GdtLen	equ	$ - $$
GdtPtr	dw	GdtLen - 1
	dd	0

SP_IN_REAL_MODE:
	dw	0

[SECTION .16]
[BITS	16]
LABEL_BEGIN:
mov	ax, cs
mov	ds, ax
mov	es, ax
mov	ss, ax
mov	sp, 0100h

mov	[SP_IN_REAL_MODE], sp
mov	[LABEL_GO_BACK_TO_REAL + 3], ax

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
add	eax, LABEL_SEG_CODE16
mov	[Code16_DESC + 2], ax
shr	eax, 16
mov	[Code16_DESC + 4], al
mov	[Code16_DESC + 7], ah


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

LABEL_REAL_ENTRY:
mov	ax, cs
mov	ds, ax
mov	es, ax
mov	ss, ax

mov	sp, [SP_IN_REAL_MODE]

in	al, 92h
and	al, 11111101b
out	92h, al

sti

mov	ax, 4c00h
int	21h





[SECTION .s16]
;ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
mov	ax, SelectorNormal
mov	ds, ax
mov	es, ax
mov	ss, ax
mov	gs, ax
mov	fs, ax

mov	eax, cr0
and	al, 11111110b
mov	cr0, eax


;mov	edi, 02dh
;mov	al, [cs:edi]
;mov	edi, 02eh
;mov	al, [cs:edi]


LABEL_GO_BACK_TO_REAL:
jmp	0:LABEL_REAL_ENTRY

Code16Len	equ $ - $$







[SECTION .32]
[BITS 32]
LABEL_SEG_CODE32:
mov	ax, SelectorVideo
mov	gs, ax
mov	edi, (80*12 + 79)*2
mov	ah, 0ch
mov	al, 'P'
mov	[gs:edi], ax

jmp	SelectorCode16:0
jmp	$

Code32Len equ	$ - $$
