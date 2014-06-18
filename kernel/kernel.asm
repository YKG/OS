SelectorFlatC		equ	8	; gdt[1]
SelectorFlatRW		equ	010h	; gdt[2]
SELECTOR_TSS		equ	020h	; gdt[4]
SA_TIL			equ	4
SA_RPL1			equ	1
TOP_REGS_OF_PROC	equ	18*4	; 18个寄存器(PROCESS)
SELECTOR_OF_PROC	equ	18*4	; 选择子在PROCESS中的偏移
RETADDR_AT_PROC_REGS	equ	12*4	; retaddr在PROCESS.REG中的偏移，即以前的error_code位置，好像中断没有error_code
EOI			equ	020h
INT_M_CTL		equ	020h	; 主8259A Controller
INT_M_CTLMASK		equ	021h	; 主8259A Mask
INT_S_CTL		equ	0A0h	; 从8259A Controller
INT_S_CTLMASK		equ	0A1h	; 从8259A Mask



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
extern	proc_table
extern	clock_handler
extern	irq_table
extern	sys_call_table



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

global	sys_call

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
;	sti		; 不应该在此处开中断，不然会引起时钟中断，那时候进程还没有呢

xchg	bx, bx
	jmp	SelectorFlatC:kernel_main

	jmp	$

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








; 中断处理
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 主 8259A
;;;;;;;;;;;;;;;
%macro hwint_master	1	
	call	save		; 下一条语句的 地址(EIP) 入栈
	
	in	al, INT_M_CTLMASK
	or	al, 1 << %1 	; 屏蔽时钟中断
	out	INT_M_CTLMASK, al

	mov	al, EOI		; 发送EOI
	out	INT_M_CTL, al
	
	sti
	push	%1		; int 0
	call	[irq_table + 4 * %1]
	add	esp, 4
	cli

	in	al, INT_M_CTLMASK
	and	al, ~(1 << %1)	; 开启时钟中断
	out	INT_M_CTLMASK, al

	ret
%endmacro



hwint00:
	hwint_master	0
hwint01:
	hwint_master	1
hwint02:
	hwint_master	2
hwint03:
	hwint_master	3
hwint04:
	hwint_master	4
hwint05:
	hwint_master	5
hwint06:
	hwint_master	6
hwint07:
	hwint_master	7
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 从 8259A
;;;;;;;;;;;;;;;
%macro hwint_slave	1	
	call	save		; 下一条语句的 地址(EIP) 入栈
	
	in	al, INT_S_CTLMASK
	or	al, 1 << (%1 - 8) ; 屏蔽时钟中断
	out	INT_S_CTLMASK, al

	mov	al, EOI		; 发送EOI
	out	INT_M_CTL, al
	
	sti
	push	%1		; int 0
	call	[irq_table + 4 * %1]
	add	esp, 4
	cli

	in	al, INT_S_CTLMASK
	and	al, ~(1 << (%1 - 8))	; 开启时钟中断
	out	INT_S_CTLMASK, al

	ret
%endmacro


hwint08:
	hwint_slave	8
hwint09:
	hwint_slave	9
hwint10:
	hwint_slave	10
hwint11:
	hwint_slave	11
hwint12:
	hwint_slave	12
hwint13:
	hwint_slave	13
hwint14:
	hwint_slave	14
hwint15:
	hwint_slave	15
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
save:
	pushad
	push	ds
	push	es
	push	fs
	push	gs
	mov	bx, ss
	mov	ds, bx
	mov	es, bx
	mov	fs, bx

	mov	ebx, esp
	
	inc	dword [ds:k_reenter]
	cmp	dword [ds:k_reenter], 0
	jne	.1
	mov	esp, TopOfStack
	push	restart
	jmp	dword [ebx + RETADDR_AT_PROC_REGS]
.1:	
	push	reenter
	jmp	dword [ebx + RETADDR_AT_PROC_REGS]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



restart:
	mov	esp, [p_proc_ready]
	lea	eax, [esp + TOP_REGS_OF_PROC]
	mov	dword [tss + 4], eax	; esp0

	mov	ax, [esp + SELECTOR_OF_PROC]
	lldt	ax

reenter:
	dec	dword [ds:k_reenter]

	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad
	
	add	esp, 4		; 越过 error_code

	iretd
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;















;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 系统调用
;;;;;;;;;;;;;;;
sys_call:
xchg	bx, bx
	call	save		; 下一条语句的 地址(EIP) 入栈
	
;	mov	al, EOI		; 发送EOI
;	out	INT_M_CTL, al	; 为什么它不用发呢？

	sti
	call	[sys_call_table + (4 * eax)]
;	mov	ebx, [p_proc_ready]		; 这样应该不对，可能发生进程切换，这样就赋错了, 应该直接用 ebx
	mov	[ebx + (4 + 8 - 1)*4], eax	; 放到 进程表 的 regs.eax 中
	cli

	ret
