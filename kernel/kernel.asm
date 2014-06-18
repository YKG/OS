SelectorFlatC		equ	8	; gdt[1]
SelectorFlatRW		equ	010h	; gdt[2]
SELECTOR_TSS		equ	028h	; gdt[5]
SA_TIL			equ	4
SA_RPL1			equ	1
TOP_REGS_OF_PROC	equ	18*4	; 18个寄存器(PROCESS)
SELECTOR_OF_PROC	equ	18*4	; 选择子在PROCESS中的偏移

extern	kernel_main
extern	cstart
extern	gdt_ptr
extern	idt_ptr
extern	tss
extern	exception_handler
extern	spurious_irq
extern	TestA
extern	DispString
extern	DispInt
extern	delay
extern	k_reenter
extern	p_proc_ready

[section .bss]
resb	2*1024
TopOfStack:
resb	2*1024
TopOfTaskStack:

[section .text]
global	_start
global	Init8259A
global	divide_error    
global	debug_exception
global	nmi          
global	overflow_exception
global	breakpoint_exception
global	bound_exception
global	undefine_opcode_exception
global	no_match_coprocessor_exception
global	double_fault_exception
global	coprocessor_segment_overrun_exception
global	invalid_tSS_exception
global	segment_not_present_exception
global	stack_segment_sault_exception
global	general_protection_exception
global	page_fault_exception
global	reserved_exception
global	math_fault_exception
global	alignment_check_exception
global	machine_check_exception
global	smid_floating_point_exception

global	hwint00
global	hwint01
global	hwint02
global	hwint03
global	hwint04
global	hwint05
global	hwint06
global	hwint07
global	hwint08
global	hwint09
global	hwint10
global	hwint11
global	hwint12
global	hwint13
global	hwint14
global	hwint15
global	hwinterupt

global	restart

_start:
;xchg	bx, bx
	mov	esp, TopOfStack

	sgdt	[gdt_ptr]
	call	cstart
	lgdt	[gdt_ptr]
	lidt	[idt_ptr]
	
	xor	eax, eax
	mov	ax, SELECTOR_TSS
	ltr	ax


	jmp	SelectorFlatC:csinit

csinit:
	sti

xchg	bx, bx
	jmp	SelectorFlatC:kernel_main

	jmp	$
	hlt


;	ud2
;	jmp	0x40:0
	xor	bl, bl
	div	bl
	jmp	0x40:0
	xor	eax, eax
	push	eax
	popfd

	hlt






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 异常处理

divide_error:
	push	0FFFFFFFFh	
	push	0		; 中断向量号 
	jmp	exception

debug_exception:
	push	0FFFFFFFFh
	push	1
	jmp	exception
nmi:
	push	0FFFFFFFFh
	push	2
	jmp	exception
overflow_exception:
	push	0FFFFFFFFh
	push	3
	jmp	exception
breakpoint_exception:
	push	0FFFFFFFFh
	push	4
	jmp	exception

bound_exception:
	push	0FFFFFFFFh
	push	5
	jmp	exception

undefine_opcode_exception:
	push	0FFFFFFFFh
	push	6
	jmp	exception

no_match_coprocessor_exception:
	push	0FFFFFFFFh
	push	7
	jmp	exception

double_fault_exception:
	push	8		; #DF 有 Error Code
	jmp	exception

coprocessor_segment_overrun_exception:
	push	0FFFFFFFFh
	push	9
	jmp	exception

invalid_tSS_exception:		; vector=0x0a
	push	10		; #TS 有 Error Code
	jmp	exception

segment_not_present_exception:	; vector=0x0b
	push	11		; #NP 有 Error Code
	jmp	exception

stack_segment_sault_exception:	; vector=0x0c
	push	12		; #SS 有 Error Code
	jmp	exception

general_protection_exception:	; vector=0x0d
xchg	bx, bx
	push	13		; #GP 有 Error Code
	jmp	exception

page_fault_exception:		; vector=0x0e
	push	14		; #PF 有 Error Code
	jmp	exception

reserved_exception:
	push	0FFFFFFFFh
	push	15
	jmp	exception

math_fault_exception:
	push	0FFFFFFFFh
	push	16
	jmp	exception

alignment_check_exception:	; vector=0x11
	push	17		; #AC 有 Error Code
	jmp	exception

machine_check_exception:
	push	0FFFFFFFFh
	push	18
	jmp	exception

smid_floating_point_exception:
	push	0FFFFFFFFh
	push	19
	jmp	exception


exception:
	call	exception_handler
	add	esp, 4*2

	hlt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 外部中断

hwint00:
xchg	bx, bx
	sub	esp, 4		; 越过 error_code
	pushad
	push	ds
	push	es
	push	fs
	push	gs

	
	mov	esp, TopOfStack
	mov	ax, SelectorFlatRW
	mov	ds, ax
	mov	es, ax
	mov	fs, ax


	inc	byte [gs:0]
	mov	al, 0x20	; 发送EOI
	out	0x20, al

	inc	dword [ds:k_reenter]
	cmp	dword [ds:k_reenter], 0
	jne	.reenter

	sti
	
	push	clock_int_msg
	call	DispString
	add	esp, 4

;	call	delay

	cli

.reenter:	
	dec	dword [ds:k_reenter]

	mov	esp, [p_proc_ready]

	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad
	
	add	esp, 4		; 越过 error_code

	iretd

	push	0		; int 0
	jmp	hwinterupt

hwint01:
	push	1		; int 1
	jmp	hwinterupt

hwint02:
	push	2
	jmp	hwinterupt

hwint03:
	push	3
	jmp	hwinterupt

hwint04:
	push	4
	jmp	hwinterupt

hwint05:
	push	5
	jmp	hwinterupt

hwint06:
	push	6
	jmp	hwinterupt

hwint07:
	push	7
	jmp	hwinterupt

hwint08:
	push	8
	jmp	hwinterupt

hwint09:
	push	9
	jmp	hwinterupt

hwint10:
	push	10
	jmp	hwinterupt

hwint11:
	push	11
	jmp	hwinterupt

hwint12:
	push	12
	jmp	hwinterupt

hwint13:
	push	13
	jmp	hwinterupt

hwint14:
	push	14
	jmp	hwinterupt

hwint15:
	push	15		; int 15
	jmp	hwinterupt



hwinterupt:
	call	spurious_irq
	add	esp, 4

	iretd			; 不要写成 ret 了 !
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 这个部分是我自己写的，所有的设置都放在 这里了。 作者的
; 放在 kernel_main.asm 里面
restart_ykg:
;restart:
xchg	bx, bx
	
	mov	word [tss + 8], ss	; ss0
	mov	dword eax, [ds:p_proc_ready]
	add	eax, TOP_REGS_OF_PROC
	mov	dword [tss + 4], eax	; esp0
	

	mov	dword ebx, [ds:p_proc_ready]
	mov	word ax, [ds:ebx + SELECTOR_OF_PROC]	; LDT选择子
	lldt	ax

	
	mov	ax, 8 + SA_RPL1 + SA_TIL
	mov	ds, ax
	mov	es, ax

	push	eax					; SS
	push	TopOfTaskStack
	push	0 + SA_RPL1 + SA_TIL			; CS
	push	TestA
xchg	bx, bx
	retf	






;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
; 这个是参照中断处理写的
restartx:
xchg	bx, bx
	
	mov	word [tss + 8], ss	; ss0
	mov	dword eax, [ds:p_proc_ready]
	add	eax, TOP_REGS_OF_PROC
	mov	dword [tss + 4], eax	; esp0
	

	mov	dword ebx, [ds:p_proc_ready]
	mov	word ax, [ds:ebx + SELECTOR_OF_PROC]	; LDT选择子
	lldt	ax

	
	mov	ax, 8 + SA_RPL1 + SA_TIL
	mov	ds, ax
	mov	es, ax

	push	eax					; SS
	push	TopOfTaskStack
	push	0 + SA_RPL1 + SA_TIL			; CS
	push	TestA
xchg	bx, bx
	retf	



restart:
xchg	bx, bx
	mov	esp, [p_proc_ready]
	lea	eax, [esp + TOP_REGS_OF_PROC]
	mov	dword [tss + 4], eax	; esp0
	
	mov	ax, [esp + SELECTOR_OF_PROC]
	lldt	ax


	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad
	
	add	esp, 4		; 越过 error_code

	iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



[section .data]
clock_int_msg:	db	'^', 0
