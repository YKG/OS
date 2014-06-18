;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%include "pm.inc"

org	0100h
xchg	bx, bx
jmp	LABEL_BEGIN



[SECTION .gdt]
LABEL_GDT:
GDT_DESC:	Descriptor	0, 0, 0
Normal_DESC:	Descriptor	0, 0ffffh, DA_DRW
Code32_DESC:	Descriptor	0, Code32Len - 1, DA_CR + DA_32 ;DA_CR, 不能是DA_C
Code16_DESC:	Descriptor	0, 0ffffh, DA_C	; 一定要注意段界限，保证为0ffffh
VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW
Stack_DESC:	Descriptor	0, TopOfStack, DA_DRW
Data_DESC:	Descriptor	0, DataLen - 1, DA_DRW

GdtLen	equ	$ - $$
GdtPtr	dw	GdtLen - 1
	dd	0

SelectorNormal	equ	Normal_DESC - GDT_DESC
SelectorCode16	equ	Code16_DESC - GDT_DESC
SelectorCode32	equ	Code32_DESC - GDT_DESC
SelectorVideo	equ	VIDEO_DESC - GDT_DESC
SelectorData	equ	Data_DESC - GDT_DESC
SelectorStack	equ	Stack_DESC - GDT_DESC



[SECTION .idt]
LABEL_IDT:

%rep	32	
	Gate	SelectorCode32,	SpuriousHandler, 0, DA_386IGate	
%endrep
.20h:	Gate	SelectorCode32, ClockHandler,	0, DA_386IGate
%rep	95	
	Gate	SelectorCode32,	SpuriousHandler, 0, DA_386IGate	
%endrep
.80h:	Gate	SelectorCode32,	UserIntHandler, 0, DA_386IGate	

IdtLen		equ	$ - $$
IdtPtr		dw	IdtLen - 1
		dd	0






[SECTION .stack]
[BITS	32]
LABEL_STACK: 
times	512	db	0	

TopOfStack	equ	$ - $$ - 1





[SECTION .data]
[BITS	32]
LABEL_DATA:

_SavedIdtr:	dw	0	; IDTR 的大小和 GDTR一致，48bit
		dd	0
_SavedIMREG:	db	0

SavedIdtr	equ	_SavedIdtr	-	$$
SavedIMREG	equ	_SavedIMREG	-	$$

DataLen		equ	$ - $$






[SECTION .s16]
[BITS	16]
LABEL_SEG_CODE16:
mov	ax, SelectorNormal
mov	ds, ax
mov	es, ax
mov	ss, ax

mov	eax, cr0
and	eax, 7ffffffeh
mov	cr0, eax	


LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY

Code16Len	equ	$ - $$












[SECTION .16]
[BITS	16]
LABEL_BEGIN:

mov	ax, cs
mov	ds, ax
mov	es, ax
mov	ss, ax
mov	sp, 0100h






;保存屏蔽中断寄存器 IMREG
sidt	[_SavedIdtr]
in	al, 21h
mov	byte	[_SavedIMREG], al


mov	ax, cs
mov	word	[LABEL_GO_BACK_TO_REAL + 3], ax



xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_STACK 
mov	word [Stack_DESC + 2], ax
shr	eax, 16
mov	byte [Stack_DESC + 4], al
mov	byte [Stack_DESC + 7], ah


xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_DATA 
mov	word [Data_DESC + 2], ax
shr	eax, 16
mov	byte [Data_DESC + 4], al
mov	byte [Data_DESC + 7], ah


xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_SEG_CODE16
mov	word [Code16_DESC + 2], ax
shr	eax, 16
mov	byte [Code16_DESC + 4], al
mov	byte [Code16_DESC + 7], ah


xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_SEG_CODE32
mov	word [Code32_DESC + 2], ax
shr	eax, 16
mov	byte [Code32_DESC + 4], al
mov	byte [Code32_DESC + 7], ah

;-----------GDT----------------------
xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_GDT
mov	dword	[GdtPtr + 2], eax

lgdt	[GdtPtr]

;-----------IDT----------------------
xor	eax, eax
mov	ax, cs
shl	eax, 4
add	eax, LABEL_IDT
mov	dword	[IdtPtr + 2], eax

cli
lidt	[IdtPtr]


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
mov	fs, ax
mov	gs, ax
mov	ss, ax


lidt	[_SavedIdtr]
;mov	al, [_SavedIMREG]
;out	21h, al


in	al, 92h
and	al, 11111101b
out	92h, al

sti

mov	ax, 4c00h
int	21h











[SECTION .32]
[BITS 32]
LABEL_SEG_CODE32:
mov	ax, SelectorVideo
mov	gs, ax
mov	ax, SelectorData
mov	ds, ax
mov	es, ax
mov	ax, SelectorStack
mov	ss, ax
mov	edi, (80*1 + 79)*2
mov	ah, 0ch
mov	al, 'P'
mov	[gs:edi], ax




call	Init8259A
int	7fh
int	80h
sti

;jmp	$
xchg	bx, bx
call	SetRealMode8259A

jmp	SelectorCode16:0
jmp	$




;==== ClockHandler ========================
_ClockHandler:
ClockHandler	equ	_ClockHandler - $$
	inc	byte	[gs:(80*3 + 75)*2]
	mov	al, 20h
	out	20h, al
	iretd

;==== ClockHandler End========================



;==== UserIntHandler ========================
_UserIntHandler:
UserIntHandler	equ	_UserIntHandler - $$
	mov	ah, 0ch
	mov	al, 'I'
	mov	[gs:(80*3 + 75)*2], ax
	;jmp	$
	iretd

;==== UserIntHandler End ====================



;==== SpuriousHandler ========================
_SpuriousHandler:
SpuriousHandler	equ	_SpuriousHandler - $$
	mov	ah, 0ch
	mov	al, '!'
	mov	[gs:(80*4 + 75)*2], ax
	;jmp	$
	iretd

;==== SpuriousHandler End ====================




;==== SetRealMode8259A ==============

SetRealMode8259A:
	mov	ax, SelectorData
	mov	fs, ax
	
	;mov	al, 00010101b
	mov	al, 00010001b
	out	020h, al
	call	io_delay

	mov	al, 008h
	out	021h, al
	call	io_delay

	mov	al, 004h
	out	021h, al
	call	io_delay

	mov	al, 001h
	out	021h, al
	call	io_delay

;	mov	al, [fs:SavedIMREG]
;	out	021h, al
	call	io_delay

	ret

;==== SetRealMode8259A End ==============










;==== Init8259A ==============
Init8259A:
mov	al, 011h
out	020h, al
call	io_delay

out	0a0h, al
call	io_delay


mov	al, 020h
out	021h, al
call	io_delay

mov	al, 028h
out	0a1h, al
call	io_delay


mov	al, 004h
out	021h, al
call	io_delay

mov	al, 002h
out	0a1h, al
call	io_delay


mov	al, 001h
out	021h, al
call	io_delay

out	0a1h, al
call	io_delay

; - - - - - - - -
mov	al, 11111110b
out	021h, al
call	io_delay

mov	al, 11111111b
out	0a1h, al
call	io_delay

ret

;---------------
io_delay:
	nop
	nop
	nop
	nop
	ret


;==== Init8259A  End ==========



Code32Len equ	$ - $$
