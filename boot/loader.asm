
%include "pm.inc"


org  0100h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行

		
	
;=============================================================================================
; FAT12 文件头
;=============================================================================================	
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
;=============================================================================================







;=============================================================================================
; GDT
;=============================================================================================
[SECTION .gdt]
LABEL_GDT:
	GDT_DESC:	Descriptor	0, 0, 0
	;Normal_DESC:	Descriptor	0, 0ffffh, DA_DRW
	FlatC_DESC:	Descriptor	0, 0ffffh, DA_C | DA_32 | DA_LIMIT_4K
	FlatRW_DESC:	Descriptor	0, 0ffffh, DA_DRW| DA_32 |DA_LIMIT_4K	; 把我害死了 DA_32 ！
	VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW
	Code32_DESC:	Descriptor	0, Code32Len - 1, DA_CR + DA_32 ;DA_CR, 不能是DA_C
	Code16_DESC:	Descriptor	0, 0ffffh, DA_C	; 一定要注意段界限，保证为0ffffh	
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
	;SelectorNormal	equ	Normal_DESC - GDT_DESC
	SelectorCode16	equ	Code16_DESC - GDT_DESC
	SelectorCode32	equ	Code32_DESC - GDT_DESC
	SelectorVideo	equ	VIDEO_DESC - GDT_DESC
	SelectorData	equ	Data_DESC - GDT_DESC
	SelectorStack	equ	Stack_DESC - GDT_DESC
	SelectorDir	equ	Page_Dir_DESC - GDT_DESC
	SelectorTbl	equ	Page_Tbl_DESC - GDT_DESC
	SelectorDir2	equ	Page_Dir_DESC2 - GDT_DESC
	SelectorTbl2	equ	Page_Tbl_DESC2 - GDT_DESC



	PageDirBase	equ	200000h
	PageTblBase	equ	201000h
	PageDirBase2	equ	210000h
	PageTblBase2	equ	211000h

	BaseDemo	equ	401000h
	BaseFoo		equ	401000h
	BaseBar		equ	501000h
;=============================================================================================








;=============================================================================================
; IDT
;=============================================================================================
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

;=============================================================================================















;=============================================================================================
; Loader 入口
;=============================================================================================
[SECTION .s16]
[BITS	16]
LABEL_START:
	mov	ax, cs
	mov	ds, ax
	mov	ss, ax
	mov	sp, 0100h


;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
; 下面是寻找并加载 KERNEL 到 KernelSeg:KernelOffset
;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	mov	ah, 000h
	mov	dl, 0		; A盘
	int	13h		; 复位软驱


	mov	ax, KernelSeg
	mov	es, ax
	mov	bx, KernelOffset; 设置es:bx 为 0x9000:0100, Kernel将放到此处
LABEL_SEARCH_IN_ROOT_DIR_LOOP:
	mov	word ax, [wSectorNoForRead]
	mov	byte [bSectorsToRead], 1	; 读1个扇区
	call	ReadSector			; 读第 19 扇区

	mov	dx, 16		; 16 = 512/32, 每扇区共16个文件属性
	mov	di, bx		
LABEL_SEARCH_KERNEL_LOOP:	; 大循环，循环dx(16)次，检查整个扇区
	mov	si, KernelName
	;-----------------------; 字符串比较-------------
	mov	cx, 11		; 'KERNEL  BIN' 共11字节
LABEL_KERNEL_NAME_CMP_LOOP:
	mov	al, [es:di]
	cmp	al, [ds:si]
	jne	LABEL_DIFFEFRENT
	inc	di
	inc	si
	loop	LABEL_KERNEL_NAME_CMP_LOOP
	jmp	LABEL_FOUND
	;------------------------------------------------
LABEL_DIFFEFRENT:
	dec	dx
	jz	LABEL_GO_TO_NEXT_SECTOR
	add	di, 32		; 每个文件属性占 32 字节
	jmp	LABEL_SEARCH_KERNEL_LOOP

LABEL_GO_TO_NEXT_SECTOR:
	inc	byte [bIndexForRootSectorLoop]
	mov	ah, byte [bIndexForRootSectorLoop]
	mov	al, byte [bRootSectorNum]
	cmp	ah, al
	je	LABEL_NOT_FOUND	
	inc	word [wSectorNoForRead]
	jmp	LABEL_SEARCH_IN_ROOT_DIR_LOOP

LABEL_NOT_FOUND:
	mov	ax, cs
	mov	ds, ax
	mov	si, KernelNoKernel
	mov	di, (80*4 + 0)*2
	call	DispString
	jmp	$	

LABEL_FOUND:
	; 打印 Loading
	push	di
	mov	ax, cs
	mov	ds, ax
	mov	si, KernelFound
	mov	di, (80*4 + 0)*2
	call	DispString
	mov	si, di		; 保存下一个字符位置到si 
	pop	di







;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;	mov	dx, KernelSeg
;	mov	es, dx
;	mov	bx, KernelOffset	; 设置es:bx 为 0x9000:0100
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$








	; 获取KERNEL.BIN第一扇区号，11是刚比较字符串时用的长度11
	mov	word ax, [es:di - 11 + 32 - 4 - 2]
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
	mov	byte [bSectorsToRead], 1	; 读1个扇区
	call	ReadSector
	pop	ax

	call	GetFATEntry			; 取下一个扇区号

	cmp	ax, 0fffh			; 0fffh 表示是最后一个扇区
	je	LABEL_KERNEL_LOADED
	add	bx, 512				; 继续加载到下一扇区
	jmp	LABEL_GO_ON_LOADING


LABEL_KERNEL_LOADED:
	call	KillMotor			; 关马达

	; 打印 Ready.
	push	di
	mov	ax, cs
	mov	ds, ax
	mov	si, KernelReady
	mov	di, (80*5 + 0)*2
	call	DispString
	mov	si, di				; 保存下一个字符位置到si
	pop	di


; 寻找并加载 KERNEL 到 KernelSeg:KernelOffset 结束 -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+









;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
; 获取可用内存
;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
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

; 已获取可用内存 -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+












;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
; 设置GDT, IDT，准备跳入保护模式
;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	;保存屏蔽中断寄存器 IMREG
;	sidt	[_SavedIdtr]
;	in	al, 21h
;	mov	byte	[_SavedIMREG], al


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
	add	eax, LABEL_SEG_CODE32
	mov	word [Code32_DESC + 2], ax
	shr	eax, 16
	mov	byte [Code32_DESC + 4], al
	mov	byte [Code32_DESC + 7], ah



	; 加载GDT
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_GDT
	mov	dword	[GdtPtr + 2], eax

	lgdt	[GdtPtr]

	; 加载IDT
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_IDT
	mov	dword	[IdtPtr + 2], eax

	cli
	lidt	[IdtPtr]

	; 打开A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 置PE位
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 进入保护模式
	jmp	dword	SelectorCode32:0	




;#############################################################
;#############################################################
;####### 神圣的一跳！ ########################################
;#############################################################
;	jmp	KernelSeg:KernelOffset
;xchg bx,bx
;	jmp	KernelSeg:0400h
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
;=================================
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
;====================================================
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
;==================================================
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
		
	mov	bx, (KernelSeg - 0x100)
	mov	es, bx
	mov	bx, KernelOffset	

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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; cls/clear 清屏
;===============
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 准备跳入PM前用到一些变量
;==============================================
	KernelSeg		equ	08000h
	KernelOffset		equ	0000h	
	KernelPhyBaseAddress	equ	KernelSeg * 010h + KernelOffset
	ReLoadKernelPhyBaseAddr	equ	030400h
	RootFirstSectorNo	equ	19	; 根目录第一扇区号


	KernelName:		db	'KERNEL  BIN'
	KernelFound:		db	'Kernel Loading', 0
	KernelNoKernel:		db	'NO KERNEL', 0
	KernelReady		db	'Ready.', 0
	bSectorsToRead:		db	0
	bRootSectorNum:		db	14	; 根目录大小(14个扇区)
	bIndexForRootSectorLoop:db	0
	wSectorNoForRead:	dw	RootFirstSectorNo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;













;=============================================================================================
; 保护模式入口
;=============================================================================================
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
	mov	esp, TopOfStack

	
	; 打印一些字符串和内存信息
	call	DispReturn
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


	; 页表切换实验
	call	SetupPaging
	call	SelectorFlatC:BaseDemo
	call	PSwitch
	call	SelectorFlatC:BaseDemo


	; 中断实验
;	call	Init8259A
;	int	7fh
;	int	80h
;	sti



	mov	ax, SelectorFlatRW
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	fs, ax


	; 重新放置 KERNEL
	call	InitKernel

	
	; 进入 KERNEL.BIN
	jmp	SelectorFlatC:ReLoadKernelPhyBaseAddr
















;+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
; 以下都是函数
;+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-


	;==== InitKernel =============================
	; 将 Kernel 放到新的位置
	;========================
	InitKernel:
		push	eax
		push	ecx
		push	edx
		push	edi
		push	esi
		push	ds
		
		
		mov	ax, SelectorFlatRW
		mov	ds, ax
		mov	edi, KernelPhyBaseAddress
		mov	word cx, [ds:edi + 02ch]	; Program Header 个数
;;;;;;;;;;;;;;;;;;;
;mov	cx, 1
; 待处理%%%%%严重错误！！！
;;;;;;;;;;;;;;;;;;;
		mov	dword eax, [ds:edi + 01ch]	; 第一个Program Header 相对于文件头的偏移
		add	eax, KernelPhyBaseAddress
		mov	esi, eax			; ds:esi 指向Program Header 内存单元
		
	KernelCopyLoop:
		test	ecx, ecx
		jz	KernelCopyComplete	

		mov	dword eax, [ds:esi]		; 检查类型
		test	eax, eax
		jz	OneProgramHeaderComplete	

		mov	dword edx, [ds:esi + 16]	; size
		push	edx
		mov	dword edx, [ds:esi + 4]		; 源地址
		add	edx, KernelSeg * 010h + KernelOffset
		push	edx
		mov	dword edx, [ds:esi + 8]		; 目标地址
		push	edx
		call	MemCopy
		add	esp, 12

	OneProgramHeaderComplete:
		add	esi, 0x20
		dec	cx
		jmp	KernelCopyLoop

	
	KernelCopyComplete:
		pop	ds
		pop	esi
		pop	edi
		pop	edx
		pop	ecx
		pop	eax

		ret
	;==== InitKernel End =========================
		



















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
		test	ecx, ecx
		jz	.CopyComplete
		mov	ax, SelectorFlatRW
		mov	ds, ax
		mov	al, [ds:esi]
		mov	[ds:edi], al
		inc	esi
		inc	edi
		dec	ecx
		jmp	.nextbyte

	.CopyComplete:
		pop	eax
		pop	ecx
		pop	esi
		pop	edi

		ret
	;==== MemCopy End ============================










	;==== ClockHandler ===========================
	_ClockHandler:
	ClockHandler	equ	_ClockHandler - $$
		inc	byte	[gs:(80*3 + 75)*2]
		mov	al, 20h
		out	20h, al
		iretd

	;==== ClockHandler End========================



	;==== UserIntHandler =========================
	_UserIntHandler:
	UserIntHandler	equ	_UserIntHandler - $$
		mov	ah, 0ch
		mov	al, 'I'
		mov	[gs:(80*3 + 75)*2], ax
		;jmp	$
		iretd

	;==== UserIntHandler End =====================



	;==== SpuriousHandler ========================
	_SpuriousHandler:
	SpuriousHandler	equ	_SpuriousHandler - $$
		mov	ah, 0ch
		mov	al, '!'
		mov	[gs:(80*4 + 75)*2], ax
		;jmp	$
		iretd

	;==== SpuriousHandler End ====================




	;==== SetRealMode8259A =======================
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
	;==== SetRealMode8259A End ===================




	;==== Init8259A ==============================
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
	;==== Init8259A  End =========================




	;==== Foo ====================================
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
	;==== Foo End =================================




	;==== Bar =====================================
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
	;==== Bar End =================================







	;==== DispMemSize =============================
	DispMemSize:
		push	esi
		push	edx
		push	ecx

		mov	esi, memChkBuf
		mov	edx, [dwMemBlockCount]

		.nextrow:
			mov	ecx, 5
			mov	edi, ARDS
		.print:
			push	dword	[esi]
			call	DispInt
			pop	dword	[edi]
			add	edi, 4
			add	esi, 4	
		loop	.print


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
		jnz	.nextrow	

		pop	ecx
		pop	edx
		pop	esi

		ret
	;==== DispMemSize End =========================




	;==== PSwitch =================================
	; Page Switch
	PSwitch:
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

	mov	ax, SelectorDir2
	mov	es, ax
	mov	edi, 0
	xor	eax, eax
	mov	eax, PageTblBase2 | PG_P | PG_USU | PG_RWW
	sdir2:	
		mov	[es:edi], eax
		add	edi, 4
		add	eax, 4*1024
	loop	sdir2


	mov	ax, SelectorTbl2
	mov	es, ax
	mov	edi, 0
	pop	eax		; eax <- ecx
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



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;修改页表;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov	ax, SelectorTbl2
	mov	es, ax
	mov	eax, BaseDemo
	shr	eax, 10		; 即 eax /= 4*1024; eax *= 4
	mov	edi, eax
	;mov	dword	eax, [es:edi]	;这句只为看看原来存的是什么
	mov	dword	[es:edi], BaseBar | PG_P | PG_USU | PG_RWW
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
	;==== PSwitch End =============================







	;==== PSwitch End =============================
	;==== SetupPaging =============================
	;Start Paging...
	SetupPaging:
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

		mov	ax, SelectorDir
		mov	es, ax
		mov	edi, 0
		xor	eax, eax
		mov	eax, PageTblBase | PG_P | PG_USU | PG_RWW
		sdir:	
			mov	[es:edi], eax
			add	edi, 4
			add	eax, 4*1024
		loop	sdir


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


		mov	eax, PageDirBase
		mov	cr3, eax
		mov	eax, cr0
		or	eax, 80000000h
		mov	cr0, eax

		jmp	short .nop
		.nop:
			nop

		ret
	;==== SetupPaging End =========================


%include "lib.inc"


Code32Len equ	$ - $$











;=============================================================================================
; 内存变量
;=============================================================================================	
[SECTION .data]
[BITS	32]
LABEL_DATA:
	_szPMMessage:		db	'In Protected Mode Now! ^_^', 0ah, 0
	_szTitle:		db	'BaseAddrL BaseAddrH LengthLow LengthHigh   Type', 0ah, 0
	_szRAMSize:		db	'RAM Size: ', 0
	_szReturn:		db	0ah, 0
	_dwDispPos:		dd	0
	_ARDS:
		_dwBAL:		dd	0
		_dwBAH:		dd	0
		_dwLL:		dd	0
		_dwLH:		dd	0
		_dwType:	dd	0

	_dwMemBlockCount:	dd	0	
	_dwRAMSize:		dd	0	
	_memChkBuf:	times	512	db	0
	_SavedIdtr:		dw	0
				dd	0
	_SavedIMREG:		db	0

	szPMMessage		equ	_szPMMessage	-	$$
	szTitle			equ	_szTitle	-	$$
	szRAMSize		equ	_szRAMSize	-	$$
	szReturn		equ	_szReturn	-	$$
	dwDispPos		equ	_dwDispPos	-	$$
	ARDS			equ	_ARDS		-	$$
		dwBAL		equ	_dwBAL		-	$$
		dwBAH		equ	_dwBAH		-	$$
		dwLL		equ	_dwLL		-	$$
		dwType		equ	_dwType		-	$$
	dwMemBlockCount		equ	_dwMemBlockCount-	$$
	dwRAMSize		equ	_dwRAMSize	-	$$
	memChkBuf		equ	_memChkBuf	-	$$
	SavedIdtr		equ	_SavedIdtr	-	$$
	SavedIMREG		equ	_SavedIMREG	-	$$

DataLen			equ	$ - $$
;=============================================================================================	









;=============================================================================================
; 栈
;=============================================================================================	
[SECTION .stack]
[BITS	32]
LABEL_STACK: 
	times	01000h	db	0	

TopOfStack	equ	$ - $$ - 1
;=============================================================================================	






