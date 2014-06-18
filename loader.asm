;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%include "pm.inc"


org  0100h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行
	jmp  LABEL_START		; Start to boot.
	nop				; 这个 nop 不可少

	; 下面是 FAT12 磁盘的头
	BS_OEMName	DB 'ForrestY'	; OEM String, 必须 8 个字节
	BPB_BytsPerSec	DW 512		; 每扇区字节数
	BPB_SecPerClus	DB 1		; 每簇多少扇区
	BPB_RsvdSecCnt	DW 1		; Boot 记录占用多少扇区
	BPB_NumFATs	DB 2		; 共有多少 FAT 表
	BPB_RootEntCnt	DW 224		; 根目录文件数最大值
	BPB_TotSec16	DW 2880		; 逻辑扇区总数
	BPB_Media	DB 0xF0		; 媒体描述符
	BPB_FATSz16	DW 9		; 每FAT扇区数
	BPB_SecPerTrk	DW 18		; 每磁道扇区数
	BPB_NumHeads	DW 2		; 磁头数(面数)
	BPB_HiddSec	DD 0		; 隐藏扇区数
	BPB_TotSec32	DD 0		; 如果 wTotalSectorCount 是 0 由这个值记录扇区数
	BS_DrvNum	DB 0		; 中断 13 的驱动器号
	BS_Reserved1	DB 0		; 未使用
	BS_BootSig	DB 29h		; 扩展引导标记 (29h)
	BS_VolID	DD 0		; 卷序列号
	BS_VolLab	DB 'OrangeS0.02'; 卷标, 必须 11 个字节
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节  





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 保护模式

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
_SavedIdtr:	dw	0
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





[SECTION .s16]
[BITS	16]
LABEL_START:

	mov	ax, cs
	mov	ds, ax
	mov	ss, ax
	mov	sp, 0100h


	mov	ah, 000h
	mov	dl, 0		; A盘
	int	13h		; 复位软驱


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 计算根目录占用的扇区数目，保存在[bRootSectorNum]中
; 下面是计算方法，为了简单起见，直接将14写在初始化里面 
;-------------------------------------------------------------------
;	mov	al, BPB_RootEntCnt
;	mov	bl, 16		; 16 = 512/32, 每扇区共16个文件属性
;	div	bl
;	mov	byte [bRootSectorNum], al ; 根目录占用的扇区数目
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	mov	ax, DestSeg
	mov	es, ax
	mov	bx, DestOffset	; 设置es:bx 为 0x9000:0100

	
LABEL_SEARCH_IN_ROOT_DIR_LOOP:
	
	mov	word ax, [wSectorNoForRead]
	mov	byte [bSectorsToRead], 1 ; 读1个扇区
	call	ReadSector	; 读第 19 扇区

	
	mov	dx, 16		; 16 = 512/32, 每扇区共16个文件属性
	mov	di, bx		

LABEL_SEARCH_LOADER_LOOP:	; 大循环，循环dx(16)次，检查整个扇区
	mov	si, LoaderName

	;-----------------------; 字符串比较
	mov	cx, 11		; 'LOADER  BIN' 共11字节
.loadername:
	mov	al, [es:di]
	cmp	al, [ds:si]
	jne	LABEL_DIFFEFRENT
	inc	di
	inc	si
	loop	.loadername
	jmp	LABEL_FOUND
	;--------------------------
	
LABEL_DIFFEFRENT:
	dec	dx
	jz	LABEL_GO_TO_NEXT_SECTOR
	add	di, 32		; 每个文件属性占 32 字节
	jmp	LABEL_SEARCH_LOADER_LOOP


LABEL_GO_TO_NEXT_SECTOR:
	inc	byte [bIndexForRootSectorLoop]
	mov	ah, byte [bIndexForRootSectorLoop]
	mov	al, byte [bRootSectorNum]
	cmp	ah, al
	je	LABEL_NOT_FOUND
	
	inc	word [wSectorNoForRead]
	jmp	LABEL_SEARCH_IN_ROOT_DIR_LOOP




LABEL_NOT_FOUND:
;	call	cls		; 清屏
	mov	ax, cs
	mov	ds, ax
	mov	si, LoaderNoLoader
	mov	di, (80*4 + 0)*2
	call	DispString
	jmp	$	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	mov	ax, 0b800h
;	mov	gs, ax
;	mov	ah, 0ch
;	mov	al, 'N'		; 没找到
;	mov	[gs:(80*3 + 3)*2], ax
;	jmp	$
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_FOUND:
xchg	bx, bx
;------------------------------------------------
;清屏
;	mov	ax, 0600h	; ah = 6, al = 0
;	mov	bx, 0700h	; 黑底白字
;	mov	cx, 0		; 左上角(0, 0)
;	mov	dx, 0184fh	; 右下角(80, 50)
;	int	10h
;------------------------------------------------
;	call	cls		; 清屏


	; 打印 Loading
	push	di
	mov	ax, cs
	mov	ds, ax
	mov	si, LoaderFound
	mov	di, (80*4 + 0)*2
	call	DispString
	mov	si, di		; 保存下一个字符位置 ？？？
	pop	di



	mov	word ax, [es:di - 11 + 32 - 4 - 2]

	mov	dx, DestSeg
	mov	es, dx
	mov	bx, DestOffset	; 设置es:bx 为 0x9000:0100

LABEL_GO_ON_LOADING:	

	; 每次循环在Loading后打印一个 '.'
	push	ax
	mov	ah, 0ch
	mov	al, '.'
	mov	word [gs:si], ax
	add	si, 2
	pop	ax





	push	ax
	add	ax, 19 + 14 - 2
	mov	byte [bSectorsToRead], 1 ; 读1个扇区
	call	ReadSector
	pop	ax



	call	GetFATEntry

	cmp	ax, 0fffh
	je	LABEL_LOADER_LOADED
	add	bx, 512		; 继续加载到下一扇区
	jmp	LABEL_GO_ON_LOADING




LABEL_LOADER_LOADED:
	call	KillMotor	; 关马达

	; 打印 Ready.
	push	di
	mov	ax, cs
	mov	ds, ax
	mov	si, LoaderReady
	mov	di, (80*5 + 0)*2
	call	DispString
	mov	si, di		; 保存下一个字符位置 ？？？
	pop	di









;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 保护模式


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



xchg	bx, bx

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

jmp	$			;;;;;;;;$$$$$$$$$$$$$$$$$$$$$$$$$

lidt	[_SavedIdtr]
mov	al, [_SavedIMREG]
out	21h, al


in	al, 92h
and	al, 11111101b
out	92h, al

sti

mov	ax, 4c00h
int	21h







;#############################################################
;#############################################################
;####### 神圣的一跳！ ########################################
;#############################################################
;	jmp	DestSeg:DestOffset
xchg bx,bx
	jmp	DestSeg:0400h
;#############################################################
;#############################################################
;#############################################################
;#############################################################









;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 关闭软驱马达
;
;=======================
KillMotor:
	push	dx
	mov	dx, 03f2h
	mov	al, 0
	out	dx, al
	pop	dx
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 读扇区
;
; 参数:
;	ax		扇区号
;	bSectorsToRead	读取扇区数
;	es:bx		存放位置
;=======================
ReadSector:
	push	ax	
	push	cx
	push	dx
	

	mov	cl, [ds:BPB_SecPerTrk]
	div	cl
	
	mov	cl, ah		
	inc	cl		; ah是余数，扇区号 = ah + 1
	mov	ch, al
	shr	ch, 1		; al是商，磁道号 = al/2
	mov	dh, al
	and	dh, 1		; 磁头号 = al & 0x1
	mov	dl, 0

.GoOnReading:
	mov	ah, 2			  ; 读
	mov	byte al, [ds:bSectorsToRead] ; 准备读的取扇区个数
	int	13h		
	jc	.GoOnReading


	pop	dx
	pop	cx
	pop	ax
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DispString
;	参数：	ds:si 指向待显示字符串，字符串以0结束 
;		di    gs:di 为待显示字符串首地址
;
DispString:
	mov	ax, 0b800h
	mov	gs, ax
	
	mov	ah, 0ch
.disp_str_go_on:
	mov	byte al, [ds:si]
	test	al, al
	jz	.return
	mov	word [gs:di], ax
	inc	si
	add	di, 2
	jmp	.disp_str_go_on

	

.return:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;GetFATEntry	取当前ax对应的FAT项，结果保存在ax中
;	参数：ax
;	返回：ax
;---------------------------------------------------------
GetFATEntry:
	push	bx
	push	cx
	push	dx
	push	es
	push	di




	xor	dx, dx
	mov	bx, 3
	mul	bx
	mov	bx, 512*2
	div	bx	
	mov	cx, ax		; 第 cx 扇区即待读取的第一个扇区(相对于FAT1)，ax是商
	mov	ax, dx
	shr	ax, 1		; ax是起始扇区起始字节，dx是余数，dx >> 1 即除以 2
	and	dx, 1
	
	
	mov	bx, (DestSeg - 0x100)
	mov	es, bx
	mov	bx, DestOffset	

	push	ax
	mov	ax, cx
	inc	ax		; FAT1前面还有一个扇区
	mov	byte [bSectorsToRead], 2 ; 读2个扇区
	call	ReadSector

	pop	ax
	mov	di, ax
	mov	word ax, [es:bx + di]

	test	dx, dx		; 判断dx是不是偶数
	jz	FAT_ENTRY_EVEN
	shr	ax, 4		; 奇数情况
	jmp	GetFATEntryReturn
FAT_ENTRY_EVEN:
	and	ax, 00fffh	; 偶数情况
		
GetFATEntryReturn:
	pop	di
	pop	es
	pop	dx
	pop	cx
	pop	bx
	
	ret







;----------------------------------------------------------------------------
; cls/clear 清屏

cls:
	push	ax
	push	bx
	push	cx
	push	dx

	mov	ax, 0600h	; ah = 6, al = 0
	mov	bx, 0700h	; 黑底白字
	mov	cx, 0		; 左上角(0, 0)
	mov	dx, 0184fh	; 右下角(80, 50)
	int	10h

	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret
;----------------------------------------------------------------------------








DestSeg			equ	08000h
DestOffset		equ	0000h	; 注意！！这个偏移要和loader第一句org后面的偏移一致，否则不能工作！
RootFirstSectorNo	equ	19	; 根目录第一扇区号


LoaderName:		db	'KERNEL  BIN'
LoaderFound:		db	'Kernel Loading', 0
LoaderNoLoader:		db	'NO KERNEL', 0
LoaderReady		db	'Ready.', 0
bSectorsToRead:		db	0
bRootSectorNum:		db	14
bIndexForRootSectorLoop:db	0
wSectorNoForRead:	dw	RootFirstSectorNo








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
mov	[gs:(80*2 + 79)*2], ax

call	DispReturn
call	DispReturn
call	DispReturn
call	DispReturn
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
sti

jmp	$
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
	
	mov	al, 00010101b
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

	mov	al, [fs:SavedIMREG]
	out	021h, al
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


