;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2011年6月25日22:02:24			;;
;;						;;
;; 今天一整天都在调试这个！还好功能上都实现了	;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%include "pm.inc"

org	0100h
xchg	bx, bx
jmp	LABEL_BEGIN


PageDirBase	equ	200000h
PageTblBase	equ	201000h



[SECTION .gdt]
GDT_DESC:	Descriptor	0, 0, 0
Normal_DESC:	Descriptor	0, 0ffffh, DA_DRW
Code32_DESC:	Descriptor	0, Code32Len - 1, DA_C + DA_32
Code16_DESC:	Descriptor	0, 0ffffh, DA_C	; 一定要注意段界限，保证为0ffffh
VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW
Stack_DESC:	Descriptor	0, TopOfStack, DA_DRW
Data_DESC:	Descriptor	0, DataLen - 1, DA_DRW
Page_Dir_DESC:	Descriptor	PageDirBase, 4095, DA_DRW  
Page_Tbl_DESC:	Descriptor	PageTblBase, 1023, DA_DRW | DA_LIMIT_4K
;Page_Tbl_DESC:	Descriptor	PageTblBase, 4096*8 - 1, DA_DRW 


GdtLen	equ	$ - $$
GdtPtr	dw	GdtLen - 1
	dd	0

SelectorNormal	equ	Normal_DESC - GDT_DESC
SelectorCode16	equ	Code16_DESC - GDT_DESC
SelectorCode32	equ	Code32_DESC - GDT_DESC
SelectorVideo	equ	VIDEO_DESC - GDT_DESC
SelectorData	equ	Data_DESC - GDT_DESC
SelectorStack	equ	Stack_DESC - GDT_DESC
SelectorDir	equ	Page_Dir_DESC - GDT_DESC
SelectorTbl	equ	Page_Tbl_DESC - GDT_DESC


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
mov	fs, ax
mov	gs, ax
mov	ss, ax

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


;xchg	bx, bx
call	SetupPaging


jmp	SelectorCode16:0
jmp	$


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





;Start Paging...

SetupPaging:

xchg	bx, bx

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

xchg	bx, bx

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


xchg	bx, bx

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



xchg	bx, bx
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
