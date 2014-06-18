;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;程序功能：
;	找磁盘上是否有LOADER.BIN文件
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



org  0100h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行
	jmp short LABEL_START		; Start to boot.
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
	call	DispStr
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
	call	DispStr
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

	; 打印 Ready.
	push	di
	mov	ax, cs
	mov	ds, ax
	mov	si, LoaderReady
	mov	di, (80*5 + 0)*2
	call	DispStr
	mov	si, di		; 保存下一个字符位置 ？？？
	pop	di



;#############################################################
;#############################################################
;####### 神圣的一跳！ ########################################
;#############################################################
;	jmp	DestSeg:DestOffset
;xchg bx,bx

	call	KillMotor
	jmp	$
;	jmp	DestSeg:0400h
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
; DispStr
;	参数：	ds:si 指向待显示字符串，字符串以0结束 
;		di    gs:di 为待显示字符串首地址
;
DispStr:
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
LoaderFound:		db	'L: Kernel Loading', 0
LoaderNoLoader:		db	'NO KERNEL', 0
LoaderReady		db	'L: Ready.', 0
bSectorsToRead:		db	0
bRootSectorNum:		db	14
bIndexForRootSectorLoop:db	0
wSectorNoForRead:	dw	RootFirstSectorNo



times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志
