
/* Standard definitions of Mode bits and Interrupt (I & F) flags in PSRs */

#define Mode_USR 0x10
#define Mode_FIQ 0x11
#define Mode_IRQ 0x12
#define Mode_SVC 0x13
#define Mode_ABT 0x17
#define Mode_UND 0x1B
#define Mode_SYS 0x1F				/* available on ARM Arch 4 and later */

#define I_Bit 0x80				/* when I bit is set, IRQ is disabled */
#define F_Bit 0x40				/* when F bit is set, FIQ is disabled */

#ifndef PROGRAM_VERSION
#define PROGRAM_VERSION "0.1"
#endif
	.section .program_version
	    .ascii PROGRAM_VERSION

/* Startup Code must be linked first at Address at which it expects to run. */

	.text
	.arm
	.section .startup, "ax"

	.global _start

L_remap:
	MOV R0, #0
	LDR R1, =L_remap
	LDR R2, =_end
L_copy_ram:
	LDR R3, [R1], #4
	STR R3, [R0], #4
	CMP R1, R2
	BLT L_copy_ram

_start:
	LDR r0, =L_NextInst
	LDR r1, =L_remap
	SUB r0, r1, r0
	LDR     pc, Reloc_L_Next_inst
L_NextInst:

/* Enter Supervisor Mode and set its Stack Pointer */
	MOV     R0, #(Mode_SVC|I_Bit|F_Bit)
	MSR     cpsr_c, R0
	LDR     sp, =__stack_end__

/* Relocate .data section (Copy from ROM to RAM) */
	LDR     r1, =_etext
	LDR     r2, =__data_start
	LDR     r3, =_edata
	LDR     r4, =L_remap
	SUB     r2, r2, r4
	SUB     r3, r3, r4
L_LoopRel:
	LDR   r0, [r1], #4
	STR   r0, [r2], #4
	CMP   r2, r3
	BLT   L_LoopRel

/* Clear .bss section (Zero init) */

	MOV     r0, #0
	LDR     r1, =__bss_start__
	LDR     r2, =__bss_end__
	LDR     r3, =L_remap
	SUB     r1, r1, r3
	SUB     r3, r2, r3
L_LoopZI:
	STR     r0, [r1], #4
	CMP     r1, r2
	BLT     L_LoopZI

/* Enter the C code, use B instruction so as to never return */
/* use BL main if you want to use c++ destructors below */
	LDR R0, =L_remap
	LDR R1, =main
	SUB R0, R1, R0
	BX R0
/*
	LDR r0, =20000000
	BX  r0
*/

Reloc_L_Next_inst:
	.word L_NextInst - L_remap
	.end
