SelectorFlatC	equ	8


extern	cstart
extern	gdt_ptr
extern	idt_ptr
extern  exception_handler

[section .bss]
resb	2*1024
TopOfStack:


[section .text]
global	_start


global	divide_error
global	single_step_exception
global	nmi
global	breakpoint_exception
global	overflow
global	bounds_check
global	inval_opcode
global	copr_not_available
global	double_fault
global	copr_seg_overrun
global	inval_tss
global	segment_not_present
global	stack_exception
global	general_protection
global	page_fault
global	copr_error



_start:
xchg	bx, bx
	mov	esp, TopOfStack

	sgdt	[gdt_ptr]
	call	cstart
	lgdt	[gdt_ptr]
	
	lidt	[idt_ptr]

	jmp	SelectorFlatC:csinit

csinit:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 大概从昨天晚饭前开始找问题，现在(2011-7-3 11:29:07)才终于知道哪里出问题了。
; 我发现进入异常处理的时候，入栈是按这个栈(ss:sp) 而不是 (ss:esp) !!!!!!!!!
; 但还不知道原因，但至少知道它push到哪里了，之前一直在ss:esp里面找，那个晕啊！
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
xchg bx, bx
	jmp 0x40:0
	ud2

		

	xor	eax, eax
	push	eax
	popfd

	hlt





; 中断和异常 -- 异常
divide_error:
	push	0xFFFFFFFF	; no err code
	push	0		; vector_no	= 0
	jmp	exception
single_step_exception:
	push	0xFFFFFFFF	; no err code
	push	1		; vector_no	= 1
	jmp	exception
nmi:
	push	0xFFFFFFFF	; no err code
	push	2		; vector_no	= 2
	jmp	exception
breakpoint_exception:
	push	0xFFFFFFFF	; no err code
	push	3		; vector_no	= 3
	jmp	exception
overflow:
	push	0xFFFFFFFF	; no err code
	push	4		; vector_no	= 4
	jmp	exception
bounds_check:
	push	0xFFFFFFFF	; no err code
	push	5		; vector_no	= 5
	jmp	exception
inval_opcode:
	push	0xFFFFFFFF	; no err code
	push	6		; vector_no	= 6
	jmp	exception
copr_not_available:
	push	0xFFFFFFFF	; no err code
	push	7		; vector_no	= 7
	jmp	exception
double_fault:
	push	8		; vector_no	= 8
	jmp	exception
copr_seg_overrun:
	push	0xFFFFFFFF	; no err code
	push	9		; vector_no	= 9
	jmp	exception
inval_tss:
	push	10		; vector_no	= A
	jmp	exception
segment_not_present:
	push	11		; vector_no	= B
	jmp	exception
stack_exception:
	push	12		; vector_no	= C
	jmp	exception
general_protection:
	push	13		; vector_no	= D
;	mov	eax, 012345678h
;	push	eax
;	mov	eax, 0ffffffffh
;	push	eax
;	mov	eax, esp
;	push	eax
;	xor	eax, eax
;	mov	ax, ss
;	push	eax
;	mov	eax, 0ffffffffh
;	push	eax
	jmp	exception
page_fault:
	push	14		; vector_no	= E
	jmp	exception
copr_error:
	push	0xFFFFFFFF	; no err code
	push	16		; vector_no	= 10h
	jmp	exception

exception:
	call	exception_handler
	add	esp, 4*2	; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
	hlt





