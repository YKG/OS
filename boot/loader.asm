%include "pm.inc.asm"

org  0100h			; 0x9000:0x100

%include "fat12hdr.inc.asm"


;=============================================================================================
; GDT
;=============================================================================================
[SECTION .gdt]
LABEL_GDT:
	GDT_DESC:	Descriptor	0, 0, 0
	FlatC_DESC:	Descriptor	0, 0ffffh, DA_C | DA_32 | DA_LIMIT_4K
	FlatRW_DESC:	Descriptor	0, 0ffffh, DA_DRW| DA_32 |DA_LIMIT_4K	; 把我害死了 DA_32 ！
	VIDEO_DESC:	Descriptor	0b8000h, 0ffffh, DA_DRW


	GdtLen	equ	$ - $$
	GdtPtr	dw	GdtLen - 1
		dd	LoaderPhyBaseAddr + LABEL_GDT

	SelectorFlatC	equ	FlatC_DESC	- GDT_DESC
	SelectorFlatRW	equ	FlatRW_DESC	- GDT_DESC
	SelectorVideo	equ	VIDEO_DESC	- GDT_DESC

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
	mov	sp, TopOfStack
	mov	ax, 0b800h
	mov	gs, ax
	

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
	call	DispStringInRealMode
	jmp	$	

LABEL_FOUND:
	; 打印 Loading
	push	di
	mov	ax, cs
	mov	ds, ax
	mov	si, KernelFound
	mov	di, (80*4 + 0)*2
	call	DispStringInRealMode
	mov	si, di		; 保存下一个字符位置到si 
	pop	di






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
	call	DispStringInRealMode
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
; 设置GDT，打开20号地址线，置PE位，准备跳入保护模式
;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

	lgdt	[GdtPtr]
	cli

	; 打开A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 置PE位
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 进入保护模式
	jmp	dword	SelectorFlatC : LoaderPhyBaseAddr + LABEL_SEG_CODE32
; 16bit 代码段结束 -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
;-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+









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
; DispStringInRealMode
;	参数：	ds:si 指向待显示字符串，字符串以0结束 
;		di    gs:di 为待显示字符串首地址
;====================================================
DispStringInRealMode:
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





;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;
; 上面部分都是 16 位代码段，从此往下开始进入保护模式
;
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



;=============================================================================================
; 保护模式入口
;=============================================================================================
[SECTION .32]
[BITS 32]
LABEL_SEG_CODE32:
	mov	ax, SelectorFlatRW
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	ss, ax
	mov	esp, LoaderPhyBaseAddr + TopOfStack
	mov	ax, SelectorVideo
	mov	gs, ax


	; 打印一些字符串和内存信息
	mov	dword [dwDispPos], (80*6 + 0)*2
	push	szPMMessage
	call	DispStr
	add	esp, 4
	push	szTitle
	call	DispStr
	add	esp, 4
	call	DispMemSize
	push	szRAMSize
	call	DispStr
	add	esp, 4
	push	dword	[dwRAMSize]
	call	DispInt
	add	esp, 4

	; 分页
	call	SetupPaging

	; 重新放置 KERNEL
	call	InitKernel

	; 进入 KERNEL.BIN
	jmp	SelectorFlatC:ReLoadKernelPhyBaseAddr




;+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
; 以下都是函数(DispMemSize, SetupPaging, InitKernel)
;+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-


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



	;==== SetupPaging =============================
	;Start Paging...
	SetupPaging:
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

		mov	edi, PageDirBase
		xor	eax, eax
		mov	eax, PageTblBase | PG_P | PG_USU | PG_RWW
		sdir:	
			mov	[es:edi], eax
			add	edi, 4
			add	eax, 4*1024
		loop	sdir
		mov	edi, PageTblBase

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
		add	edx, KernelPhyBaseAddress	; KernelSeg * 010h + KernelOffset
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
		


%include "lib.inc.asm"


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





	PageDirBase		equ	100000h
	PageTblBase		equ	101000h
	LoaderPhyBaseAddr	equ	090000h	; 自身(Loader)被加载的段的物理基址
	KernelSeg		equ	08000h
	KernelOffset		equ	0000h	
	KernelPhyBaseAddress	equ	KernelSeg * 010h + KernelOffset
	ReLoadKernelPhyBaseAddr	equ	030400h
	RootFirstSectorNo	equ	19	; 根目录第一扇区号


	szPMMessage		equ	_szPMMessage	+	LoaderPhyBaseAddr
	szTitle			equ	_szTitle	+	LoaderPhyBaseAddr
	szRAMSize		equ	_szRAMSize	+	LoaderPhyBaseAddr
	szReturn		equ	_szReturn	+	LoaderPhyBaseAddr
	dwDispPos		equ	_dwDispPos	+	LoaderPhyBaseAddr
	ARDS			equ	_ARDS		+	LoaderPhyBaseAddr
		dwBAL		equ	_dwBAL		+	LoaderPhyBaseAddr
		dwBAH		equ	_dwBAH		+	LoaderPhyBaseAddr
		dwLL		equ	_dwLL		+	LoaderPhyBaseAddr
		dwType		equ	_dwType		+	LoaderPhyBaseAddr
	dwMemBlockCount		equ	_dwMemBlockCount+	LoaderPhyBaseAddr
	dwRAMSize		equ	_dwRAMSize	+	LoaderPhyBaseAddr
	memChkBuf		equ	_memChkBuf	+	LoaderPhyBaseAddr
	SavedIdtr		equ	_SavedIdtr	+	LoaderPhyBaseAddr
	SavedIMREG		equ	_SavedIMREG	+	LoaderPhyBaseAddr



	KernelName:		db	'KERNEL  BIN'
	KernelFound:		db	'Kernel Loading', 0
	KernelNoKernel:		db	'NO KERNEL', 0
	KernelReady		db	'Ready.', 0
	bSectorsToRead:		db	0
	bRootSectorNum:		db	14	; 根目录大小(14个扇区)
	bIndexForRootSectorLoop:db	0
	wSectorNoForRead:	dw	RootFirstSectorNo



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


