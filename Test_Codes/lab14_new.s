@ Created by Rajat Jaiswal ®
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    b Reset		@ Address 0x000
	b Undef		@ Address 0x004
	b SWI		@ Address 0x008
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
gap1:	.space 0x00C
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	b IRQ		@ Address 0x018
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
gap2:	.space 0x024
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Reset:			@ Address 0x040
    @ Setting R9 
    mov r9, #0
    @ Setting starter value on display
    mov r12, #0xFF
    orr r12, r12, r12, LSL #8
    @ Initialise supervisor sp to 0x400
	mov r10, #0x10
	mov sp, r10, LSL #6
    mov r0, #0x10
    andeq r0,r0,r0
	@ msr cpsr, r0		    @ User mode set with IRQ ENABLED
	b User
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Undef:	
    @ Nothing needs to be done in-case of an undefined exception
	movs pc, lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
SWI:	
    cmp r0, #1  @ Read_Key
    beq Read_Key
    cmp r0, #2  @ Display Single
    beq Digit_1
    cmp r0, #3  @ Display 4-Digit
    beq Digit_4
	movs pc, lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IRQ:	
    @ Looped IRQ
    @ Works according to R9 (State parameter)
    cmp r9, #0
    moveq r10, #7
    cmp r9, #1
    moveq r10, #11
    cmp r9, #2
    moveq r10, #13
    cmp r9, #3
    moveq r10, #14
    moveq r9, #0
    addne r9, r9, #1
	movs pc, lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Read_Key:
    @ Working : Waits for IRQ in infinite loop
    @ Returns the read value in R1
    mov r2, r11
    movs pc, lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Digit_1:
    @ Assumption
    @ Value stored in R1
    @ Position stores in R2 (0-3)
    @ Returns Key Display in R1
    mov r2, r2, LSL #2
    mov r1, r1, LSL r2
    movs pc, lr 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Digit_4:
    @ Assumption
    @ Value stored in R1, R2, R3, R4
    @ Returns Key Display in R1
    mov r1, r1, LSL #4
    orr r1, r1, r2
    mov r1, r1, LSL #4
    orr r1, r1, r3
    mov r1, r1, LSL #4
    orr r1, r1, r4
    movs pc, lr 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
gap3:	.space 0x324
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
User:				                @ ADDRESS #400
    @Initialise user sp to 0x1000
	mov sp, r10, LSL #8
    mov r10, #0	    
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ USER CODE STARTS HERE

    @ Demonstrating (DISPLAY-1)
        @ Read (Single Digit)
    mov r0, #1          @ Read mode
    swi 0               @ Calling for digit read
    @ Read Complete
    mov r3, r2
    @ Displaying at different positions
    mov r0, #1          @ Display-1 mode
        @Position (Right Extreme)
    mov r2, #0
    mov r1, r3
    swi 0
    mov r12, r1         @ Display!
        @Position (Right Middle)
    mov r2, #1
    mov r1, r3
    swi 0
    mov r12, r1         @ Display!
        @Position (Left Middle)
    mov r2, #2
    mov r1, r3
    swi 0
    mov r12, r1         @ Display!
        @Position (Left Extreme)
    mov r2, #3
    mov r1, r3
    swi 0
    mov r12, r1         @ Display!
	.end
