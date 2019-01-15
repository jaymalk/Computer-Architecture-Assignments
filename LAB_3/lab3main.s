.extern expression, prints, fgets, itoa
.text

@ ldr r0,=InFileName
@ mov r1, #0
@ swi SWI_Open
@ ldr r1, =InputFileHandle
@ str r0, [r1]
@ ldr r0, =InputFileHandle
@ mov r2, #100
@ ldr r10,[r0]

_start:
    loop:
    ldr R0, =bufferSpace
    mov R1, #100
    mov R2, R10
    bl fgets
    cmp R0,#0
    beq exit
    mov R2, R0             @ Load the expression in R2
    mov R5, #0             @stores the result of Expression function
    mov R6, #0             @position in string
    ldrb R7,[R2, R6]       @It is character in string
    mov R8, #0             @ Variable for multiplication storage
    mov R9, #10            @ For multiplication by 10

    bl expression
    ldr R0, =outputMessage
    bl prints
    mov R0, R5
    ldr R1, =bufferSpace
    
    bl itoa
    bl prints


    

  exit:
    ldr R0, =exitMessage
    bl prints
    mov R0, #0x18
    mov R1, #0
    swi 0x123456

.data    
    inputMessage: .asciz "\nEnter  an  expression  to  be  evaluated: "
    outputMessage: .asciz "Expression evaluates to: "
    exitMessage: .asciz "\nExiting the program now."
    bufferSpace: .space 100
    

.end
 