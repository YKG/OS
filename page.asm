%include "pm.inc"

org	0100h
xchg	bx, bx
jmp	LABEL_BEGIN


PageDirBase	equ	200000h
PageTblBase	equ	201000h



[SECTION .gdt]
GDT_DESC:	Descriptor	0, 0, 0
Code32_DESC:	Descriptor	0, Code32Len - 1, DA_C + DA_32
VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW
Page_Dir_DESC:	Descriptor	PageDirBase, 4095, DA_DRW  
Page_Tbl_DESC:	Descriptor	PageTblBase, 1023, DA_DRW | DA_LIMIT_4K


GdtLen	equ	$ - $$
GdtPtr	dw	GdtLen - 1
	dd	0

SelectorCode32	equ	Code32_DESC - GDT_DESC
SelectorVideo	equ	VIDEO_DESC - GDT_DESC
SelectorDir	equ	Page_Dir_DESC - GDT_DESC
SelectorTbl	equ	Page_Tbl_DESC - GDT_DESC


[SECTION .16]
[BITS	16]
LABEL_BEGIN:

mov	ax, cs
mov	ds, ax
mov	es, ax
mov	ss, ax
mov	sp, 0100h


xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_SEG_CODE32
mov	word [Code32_DESC + 2], ax
shr	eax, 16
mov	byte [Code32_DESC + 4], al
mov	byte [Code32_DESC + 7], ah


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





;Start Paging...

mov	ax, SelectorDir
mov	es, ax
mov	edi, 0
xor	eax, eax
mov	eax, PageTblBase | PG_P | PG_USU | PG_RWW
mov	cx, 1024
sdir:	
	mov	[es:edi], eax
	add	edi, 4
	add	eax, 4*1024
loop	sdir



mov	ax, SelectorTbl
mov	es, ax
mov	edi, 0
xor	eax, eax
mov	eax, PG_P | PG_USU | PG_RWW
mov	ecx, 1024*1024
stbl:	
	mov	[es:edi], eax
	add	edi, 4
	add	eax, 4*1024
loop	stbl



mov	eax, PageDirBase
mov	cr3, eax
mov	eax, cr0
or	eax, 80000000h
mov	cr0, eax




jmp	$

Code32Len equ	$ - $$
