;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%include "pm.inc"

org	0100h			; 这个要和loader加载到的段的偏移一致，对应boot.asm中的DestOffset
xchg	bx, bx
jmp	LABEL_BEGIN


PageDirBase	equ	200000h
PageTblBase	equ	201000h
PageDirBase2	equ	210000h
PageTblBase2	equ	211000h

BaseDemo	equ	401000h
BaseFoo		equ	401000h
BaseBar		equ	501000h



[SECTION .gdt]
LABEL_GDT:
GDT_DESC:	Descriptor	0, 0, 0
Normal_DESC:	Descriptor	0, 0ffffh, DA_DRW
FlatC_DESC:	Descriptor	0, 0ffffh, DA_C | DA_32 | DA_LIMIT_4K
FlatRW_DESC:	Descriptor	0, 0ffffh, DA_DRW| DA_LIMIT_4K
Code32_DESC:	Descriptor	0, Code32Len - 1, DA_CR + DA_32 ;DA_CR, 不能是DA_C
Code16_DESC:	Descriptor	0, 0ffffh, DA_C	; 一定要注意段界限，保证为0ffffh
VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW
Stack_DESC:	Descriptor	0, TopOfStack, DA_DRW
Data_DESC:	Descriptor	0, DataLen - 1, DA_DRW
Page_Dir_DESC:	Descriptor	PageDirBase, 4095, DA_DRW  
Page_Tbl_DESC:	Descriptor	PageTblBase, 1023, DA_DRW | DA_LIMIT_4K
;Page_Tbl_DESC:	Descriptor	PageTblBase, 4096*8 - 1, DA_DRW 
Page_Dir_DESC2:	Descriptor	PageDirBase2, 4095, DA_DRW  
Page_Tbl_DESC2:	Descriptor	PageTblBase2, 4096*8 - 1, DA_DRW 


GdtLen	equ	$ - $$
GdtPtr	dw	GdtLen - 1
	dd	0

SelectorFlatC	equ	FlatC_DESC - GDT_DESC
SelectorFlatRW	equ	FlatRW_DESC - GDT_DESC
SelectorNormal	equ	Normal_DESC - GDT_DESC
SelectorCode16	equ	Code16_DESC - GDT_DESC
SelectorCode32	equ	Code32_DESC - GDT_DESC
SelectorVideo	equ	VIDEO_DESC - GDT_DESC
SelectorData	equ	Data_DESC - GDT_DESC
SelectorStack	equ	Stack_DESC - GDT_DESC
SelectorDir	equ	Page_Dir_DESC - GDT_DESC
SelectorTbl	equ	Page_Tbl_DESC - GDT_DESC
SelectorDir2	equ	Page_Dir_DESC2 - GDT_DESC
SelectorTbl2	equ	Page_Tbl_DESC2 - GDT_DESC








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
_szPMMessage:	db	'In Protected Mode Now! ^_^', 0ah, 0

_szTitle:	db	'BaseAddrL BaseAddrH LengthLow LengthHigh   Type', 0ah, 0	

_szRAMSize:	db	'RAM Size: ', 0

_szReturn:	db	0ah, 0

_dwDispPos:	dd	0

_ARDS:
	_dwBAL:		dd	0
	_dwBAH:		dd	0
	_dwLL:		dd	0
	_dwLH:		dd	0
	_dwType:	dd	0

_dwMemBlockCount:	dd	0	
_dwRAMSize:	dd	0	
_memChkBuf:	times	512	db	0
_SavedIdtr:	dw	0	; IDTR 的大小和 GDTR一致，48bit
		dd	0
_SavedIMREG:	db	0

szPMMessage	equ	_szPMMessage	-	$$
szTitle		equ	_szTitle	-	$$
szRAMSize	equ	_szRAMSize	-	$$
szReturn	equ	_szReturn	-	$$
dwDispPos	equ	_dwDispPos	-	$$
ARDS		equ	_ARDS		-	$$
	dwBAL	equ	_dwBAL		-	$$
	dwBAH	equ	_dwBAH		-	$$
	dwLL	equ	_dwLL		-	$$
	dwType	equ	_dwType		-	$$
dwMemBlockCount	equ	_dwMemBlockCount-	$$
dwRAMSize	equ	_dwRAMSize	-	$$
memChkBuf	equ	_memChkBuf	-	$$
SavedIdtr	equ	_SavedIdtr	-	$$
SavedIMREG	equ	_SavedIMREG	-	$$

DataLen		equ	$ - $$


[SECTION .s16]
[BITS	16]
LABEL_SEG_CODE16:
mov	ax, SelectorNormal
mov	ds, ax
mov	es, ax
mov	fs, ax
mov	gs, ax
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




;获取可用内存

xor	ebx, ebx
mov	ax, cs
mov	es, ax
mov	di, _memChkBuf
memChk:
mov	ax, 0e820h
movzx	eax, ax
mov	ecx, 20
mov	edx, 0534d4150h
int	15h
jc	memChkFaild
inc	dword	[_dwMemBlockCount]
test	ebx, ebx
je	memChkOK
add	di, 20
jmp	memChk
	

memChkFaild:
	mov	dword	[_dwMemBlockCount], 0
memChkOK:



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
mov	dword	[dwDispPos], edi


;打印内存信息

;mov	ax, SelectorVideo
;mov	gs, ax
;mov	edi, (80*12 + 79)*2
call	DispReturn
call	DispReturn
mov	ah, 0ch
mov	al, 'Q'
mov	dword	edi, [dwDispPos]
mov	[gs:edi], ax

call	DispReturn
push	szPMMessage
call	DispStr
add	esp, 4
call	DispReturn

push	012345678h
call	DispInt
add	esp, 4


call	DispReturn
call	DispReturn


push	szTitle
call	DispStr
add	esp, 4
call	DispMemSize


call	DispReturn
push	szRAMSize
call	DispStr
add	esp, 4
push	dword	[dwRAMSize]
call	DispInt
add	esp, 4



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
xchg	bx, bx
;放置Foo的代码到BaseFoo(0x401000)处
mov	ax, SelectorFlatRW
mov	es, ax
mov	esi, BaseFoo
mov	ax, SelectorCode32;cs
mov	ds, ax
mov	edi, LABEL_Foo - $$
mov	cx, Foo_Len
.cpyfoo:
	mov	byte	al, [ds:edi]
	mov	byte	[es:esi], al
	inc	edi
	inc	esi
loop	.cpyfoo

;-------------------------------------

xchg	bx, bx
;放置Bar的代码到BaseBar(0x501000)处
mov	ax, SelectorFlatRW
mov	es, ax
mov	esi, BaseBar
mov	ax, cs
mov	ds, ax
mov	edi, LABEL_Bar - $$
mov	cx, Bar_Len
.cpybar:
	mov	byte	al, [ds:edi]
	mov	byte	[es:esi], al
	inc	edi
	inc	esi
loop	.cpybar


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



xchg	bx, bx
call	SetupPaging

xchg	bx, bx
call	SelectorFlatC:BaseDemo



;xchg	bx, bx

;call	SelectorFlatC:BaseBar

xchg	bx, bx
xor	eax, eax
call	PSwitch
call	SelectorFlatC:BaseDemo



call	Init8259A
int	7fh
int	80h
;sti

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













;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LABEL_Foo:
mov	ax, SelectorVideo
mov	gs, ax

mov	edi, (80*20 + 0)*2
mov	ah, 0ch
mov	al, 'F'
mov	[gs:edi], ax

mov	edi, (80*20 + 1)*2
mov	ah, 0ch
mov	al, 'o'
mov	[gs:edi], ax

mov	edi, (80*20 + 2)*2
mov	ah, 0ch
mov	al, 'o'
mov	[gs:edi], ax

retf
Foo_Len		equ	$ - LABEL_Foo


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LABEL_Bar:
mov	ax, SelectorVideo
mov	gs, ax

mov	edi, (80*21 + 0)*2
mov	ah, 0ch
mov	al, 'B'
mov	[gs:edi], ax

mov	edi, (80*21 + 1)*2
mov	ah, 0ch
mov	al, 'a'
mov	[gs:edi], ax

mov	edi, (80*21 + 2)*2
mov	ah, 0ch
mov	al, 'r'
mov	[gs:edi], ax

retf
Bar_Len		equ	$ - LABEL_Bar




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispMemSize:

push	esi
push	edx
push	ecx


mov	esi, memChkBuf
mov	edx, [dwMemBlockCount]

.loop:
	mov	ecx, 5
	mov	edi, ARDS
.print:
	push	dword	[esi]
	call	DispInt
	pop	dword	[edi]
	add	edi, 4
	add	esi, 4	
loop	.print


;xchg	bx, bx

mov	dword	eax, [dwType]
cmp	eax, 1
jne	.next	

mov	dword	eax, [dwBAL]
add	eax, [dwLL]
cmp	eax, [dwRAMSize]
jb	.next
mov	dword	[dwRAMSize], eax

.next:
call	DispReturn
dec	edx
test	edx, edx
jnz	.loop	

pop	ecx
pop	edx
pop	esi

ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Page Switch

PSwitch:

;xchg	bx, bx

mov	ax, SelectorData
mov	ds, ax
mov	es, ax

xor	edx, edx
mov	dword eax, [dwRAMSize]
mov	ebx, 400000h
div	ebx
mov	ecx, eax
test	edx, edx
jz	.no_remainder2
inc	ecx
.no_remainder2:
push	ecx

;xchg	bx, bx

mov	ax, SelectorDir2
mov	es, ax
mov	edi, 0
xor	eax, eax
mov	eax, PageTblBase2 | PG_P | PG_USU | PG_RWW
;mov	cx, 1024
sdir2:	
	mov	[es:edi], eax
	add	edi, 4
	add	eax, 4*1024
loop	sdir2


;xchg	bx, bx

mov	ax, SelectorTbl2
mov	es, ax
mov	edi, 0
pop	eax
mov	ebx, 1024
mul	ebx
mov	ecx, eax
xor	eax, eax
mov	eax, PG_P | PG_USU | PG_RWW
stbl2:	
	mov	[es:edi], eax
	add	edi, 4
	add	eax, 4*1024
loop	stbl2




;xchg	bx, bx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;修改页表;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov	ax, SelectorTbl2
mov	es, ax
mov	eax, BaseDemo
shr	eax, 10		; 即 eax /= 4*1024; eax *= 4
mov	edi, eax
mov	dword	eax, [es:edi]	;这句只为看看原来存的是什么
mov	dword	[es:edi], BaseBar | 7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;修改结束;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


mov	eax, PageDirBase2
mov	cr3, eax
mov	eax, cr0
or	eax, 80000000h
mov	cr0, eax

jmp	short .nop2
.nop2:
	nop
ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Start Paging...

SetupPaging:

;xchg	bx, bx
mov	ax, SelectorData
mov	ds, ax
mov	es, ax

xor	edx, edx
mov	dword eax, [dwRAMSize]
mov	ebx, 400000h
div	ebx
mov	ecx, eax
test	edx, edx
jz	.no_remainder
inc	ecx
.no_remainder:
push	ecx

;xchg	bx, bx

mov	ax, SelectorDir
mov	es, ax
mov	edi, 0
xor	eax, eax
mov	eax, PageTblBase | PG_P | PG_USU | PG_RWW
;mov	cx, 1024
sdir:	
	mov	[es:edi], eax
	add	edi, 4
	add	eax, 4*1024
loop	sdir


;xchg	bx, bx

mov	ax, SelectorTbl
mov	es, ax
mov	edi, 0
pop	eax
mov	ebx, 1024
mul	ebx
mov	ecx, eax
xor	eax, eax
mov	eax, PG_P | PG_USU | PG_RWW
stbl:	
	mov	[es:edi], eax
	add	edi, 4
	add	eax, 4*1024
loop	stbl



;xchg	bx, bx
mov	eax, PageDirBase
mov	cr3, eax
mov	eax, cr0
or	eax, 80000000h
mov	cr0, eax

jmp	short .nop
.nop:
	nop

ret

%include "lib.inc"


jmp	$

Code32Len equ	$ - $$
