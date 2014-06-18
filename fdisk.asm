;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 软盘读取示例
;==============================================================
; 读根目录区(第19扇区)到 es:bx
;	第19扇区在磁盘上是 第1面——第0磁道——第2扇区
;--------------------------------------------------------------
;		
;		mov	dl, 0		; A 盘
;		mov	dh, 1		; 磁头号(面)
;		mov	ch, 0		; 柱面(磁道)
;		mov	cl, 2		; 扇区号(1开始)
;
;	.GoOnReading:
;		mov	ah, 02h		; 读
;		mov	al, 1		; 准备读的取扇区个数
;		int	13h		
;		jc	.GoOnReading
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	



org  07c00h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行
xchg	bx, bx
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


	mov	ax, DestSeg
	mov	es, ax
	mov	bx, DestOffset	; 设置es:bx 为 0x9000:0

	

	mov	ax, 19		
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
	mov	ax, 0b800h
	mov	gs, ax
	mov	ah, 0ch
	mov	al, 'N'		; 没找到
	mov	[gs:(80*3 + 3)*2], ax
	jmp	$


LABEL_FOUND:
	mov	ax, 0b800h
	mov	gs, ax
	mov	ah, 0ch
	mov	al, 'Y'		; 找到了
	mov	[gs:(80*3 + 3)*2], ax
	jmp	$




	


	jmp	$

	
	mov	ax, 1		; 读 1 扇区
	call	ReadSector

	jmp	$



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 读扇区
;
; 参数:
;	ax	扇区号
;	es:bx	存放位置
;=======================
ReadSector:
	push	ax
	push	cx
	push	dx

	mov	cl, [BPB_SecPerTrk]
	div	cl
	
	mov	cl, ah		
	inc	cl		; ah是余数，扇区号 = ah + 1
	mov	ch, al
	shr	ch, 1		; al是商，磁道号 = al/2
	mov	dh, al
	and	dh, 1		; 磁头号 = al & 0x1
	mov	dl, 0

.GoOnReading:
	mov	ah, 2		; 读
	mov	al, 1		; 准备读的取扇区个数
	int	13h		
	jc	.GoOnReading


	pop	dx
	pop	cx
	pop	ax
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




DestSeg		equ	09000h
DestOffset	equ	0



LoaderName:	db	'LOADER  BIN'




times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志
