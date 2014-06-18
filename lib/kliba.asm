INT_M_CTL		equ	020h	; 主8259A Controller
INT_M_CTLMASK		equ	021h	; 主8259A Mask
INT_S_CTL		equ	0A0h	; 主8259A Controller
INT_S_CTLMASK		equ	0A1h	; 主8259A Mask




extern	disp_pos

[section .text]
global	DispString
global	disp_color_str
global	DispInt
global	disp_int
global	out_byte
global	in_byte
global	disable_irq
global	enable_irq








;==== disable_irq ============================
; disable_irq(u32 irq)
;=========================================
disable_irq:
	mov	ecx, [esp + 4]
	pushf
	mov	ah, 1
	shl	ah, cl
	cmp	cl, 8
	jae	disable_8
disable_0:
	in	al, INT_M_CTLMASK
	test	al, ah
	jz	dis_already		; 不知道为啥 al == ah 就能判断已经屏蔽了？其他的屏蔽会影响这个结果啊
	or	al, ah
	out	INT_M_CTLMASK, al
	mov	eax, 1
	popf
	ret
disable_8:
	in	al, INT_S_CTLMASK
	test	al, ah
	jz	dis_already		; 不知道为啥 al == ah 就能判断已经屏蔽了？其他的屏蔽会影响这个结果啊
	or	al, ah
	out	INT_S_CTLMASK, al
	mov	eax, 1
	popf
	ret
dis_already:
	xor	eax, eax
	popf
	ret
;==== disable_irq End ========================




;==== enable_irq =============================
; enable_irq(u32 irq)
;=========================================
enable_irq:
xchg	bx, bx
	mov	ecx, [esp + 4]
	pushf
	cli				; 忘记了！
	mov	ah, ~1
	rol	ah, cl			; 这个应该是循环移位的意思，最高位会被移动到最低位
	cmp	cl, 8
	jae	enable_8
enable_0:
	in	al, INT_M_CTLMASK
	and	al, ah
	out	INT_M_CTLMASK, al	
	popf
	ret
enable_8:
	in	al, INT_S_CTLMASK
	and	al, ah
	out	INT_S_CTLMASK, al	
	popf
	ret
;==== enable_irq End =========================







;==== DispString =============================
; DispString(char *str)
;=========================================
DispString:
	push	eax
	push	ebx
	push	edx
	push	esi
	push	edi
	
	mov	dword esi, [esp + 20 + 4]	; 字符串指针, 记得 eip！
	mov	dword edi, [disp_pos]

.NextChar:	
	mov	byte al, [ds:esi]
	test	al, al
	jz	.DispComplete
	cmp	al, 0Ah
	je	.DispReturn
	mov	ah, 0bh				; 青色
	mov	word [gs:di], ax
	inc	esi
	add	di, 2
	jmp	.NextChar
.DispReturn:
	; 换行
	xor	eax, eax
	xor	edx, edx
	mov	bx, 80*2
	mov	ax, di
	div	bx
	inc	ax
	mul	bx
	mov	di, ax
	inc	esi
	jmp	.NextChar

.DispComplete:
	mov	dword [disp_pos], edi

	pop	edi
	pop	esi
	pop	edx
	pop	ebx
	pop	eax

	ret
;==== DispString End =========================





;==== disp_color_str =========================
; disp_color_str(char *str, u8 color)
;=========================================
disp_color_str:
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	

	mov	dword esi, [esp + 24 + 4]	; 字符串指针, 记得 eip！
	mov	dword ecx, [esp + 24 + 4 + 4]	; color
	mov	dword edi, [disp_pos]

.NextChar:	
	mov	byte al, [ds:esi]
	test	al, al
	jz	.DispComplete
	cmp	al, 0Ah
	je	.DispReturn
	mov	ah, cl				; cl 颜色
	mov	word [gs:di], ax
	inc	esi
	add	di, 2
	jmp	.NextChar
.DispReturn:
	; 换行
	xor	eax, eax
	xor	edx, edx
	mov	bx, 80*2
	mov	ax, di
	div	bx
	inc	ax
	mul	bx
	mov	di, ax
	inc	esi
	jmp	.NextChar

.DispComplete:
	mov	dword [disp_pos], edi

	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	ret
;==== disp_color_str End =====================








;==== disp_int ==============================
; disp_int(int i)				; 不打印前导0
;=========================================
disp_int:
	push	eax
	push	ebx
	push	ecx
	push	edx				; dl 用来标识整数前导0，0表示还没有输出
	push	esi
	push	edi
	

	mov	dword esi, [esp + 24 + 4]	; 记得 eip！
	mov	dword edi, [disp_pos]

	mov	ah, 0Bh				; 青色	
	mov	al, '0'
	mov	[gs:edi], ax
	add	edi, 2
	mov	al, 'x'
	mov	[gs:edi], ax
	add	edi, 2
	
	xor	edx, edx
	mov	ch, 8				; 8 = 32/4, 一个字符包含 4bit
	mov	cl, 32				
.next4bit:
	test	ch, ch
	jz	.dispIntComplete
	mov	ebx, esi
	sub	cl, 4
	shr	ebx, cl				; 移位操作只能使用cl寄存器或立即数
	and	bl, 00Fh
	mov	al, bl
	add	al, '0'
	cmp	bl, 10
	jb	.lowerThan10
	mov	al, bl
	sub	al, 10
	add	al, 'A'
.lowerThan10:
	cmp	ch, 1
	je	.printdigit
	cmp	al, '0'
	jne	.printdigit
	test	dl, dl
	jz	.leading0
.printdigit:
	mov	[gs:edi], ax
	add	edi, 2
	inc	dl
.leading0:	
	dec	ch
	jmp	.next4bit


.dispIntComplete:
	mov	dword [disp_pos], edi

	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	ret

;==== disp_int End ==========================








;==== out_byte ===============================
; out_byte(u16 port, u8 value)
;============================
out_byte:
	mov	edx, [esp + 4]
	mov	byte al, [esp + 4 + 4]
	out	dx, al
	call	io_delay
	ret
;==== out_byte End ===========================



;==== in_byte ================================
; in_byte(u16 port)  al = value;
;=============================
in_byte:
	mov	edx, [esp + 4]
	in	al, dx
	call	io_delay
	ret
;==== in_byte End ============================



;==== io_delay ===============================
; io_delay(int i)
;=========================================
io_delay:
	nop
	nop
	nop
	nop
	ret
;==== io_delay End ===========================
















;==== DispInt ================================
; DispInt(int i)
;=========================================
DispInt:
	push	eax
	push	ebx
	push	ecx
	push	esi
	push	edi
	

	mov	dword esi, [esp + 20 + 4]	; 记得 eip！
	mov	dword edi, [disp_pos]

	mov	ah, 0Bh				; 青色	
	mov	al, '0'
	mov	[gs:edi], ax
	add	edi, 2
	mov	al, 'x'
	mov	[gs:edi], ax
	add	edi, 2


	mov	ch, 8				; 8 = 32/4, 一个字符包含 4bit
	mov	cl, 32				
.Next4bit:
	test	ch, ch
	jz	.DispIntComplete
	mov	ebx, esi
	sub	cl, 4
	shr	ebx, cl				; 移位操作只能使用cl寄存器或立即数
	and	bl, 00Fh
	mov	al, bl
	add	al, '0'
	cmp	bl, 10
	jb	.LowerThan10
	mov	al, bl
	sub	al, 10
	add	al, 'A'
.LowerThan10:
	mov	[gs:edi], ax
	add	edi, 2
	dec	ch
	jmp	.Next4bit


.DispIntComplete:
	mov	dword [disp_pos], edi

	pop	edi
	pop	esi
	pop	ecx
	pop	ebx
	pop	eax

	ret

;==== DispInt End ============================

