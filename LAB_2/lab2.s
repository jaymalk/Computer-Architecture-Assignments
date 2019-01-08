
  .equ SWI_PrInt, 0x6b  @ Write an Integer
  .equ Stdout, 1        @ Set output mode to be Output View
  .equ SWI_Exit, 0x11   @ Stop execution

  .text

  mov R0, #Stdout        @ Set the output mode
  ldr R2, =myExp         @ Load the expression = p
  mov R5, #0             @stores the result of Expression function
  mov R6, #0             @position in string
  ldrb R7,[R2, R6]       @It is character in string
  mov R8, #0             @ Variable for multiplication storage
  mov R9, #10            @ For multiplication by 10

@@@Call Expression
bl expression
b exit

@No need to temporarily store value of R3 in stack.
@ Result is stored in R3, Don't use R3 anywhere else.
constant:
  mov R3, #0                @ Start of constant, set R3 0

  constLoop:
    ldrb R7,[R2, R6]        @ Load the character in R7
    cmp R7,#47              @ Check for int
    ble constEnd            @ If not, exit constant
    cmp R7,#58              @ Check for int
    bge constEnd            @ If not, exit constant

    mul R8, R3, R9          @ Multiply present val in R3 with 10
    mov R3, R8              @ Move back the value
    add R3, R3, R7          @ Add the new value
    sub R3, R3, #48         @ Subtract the additional ascii 0
    add R6,R6, #1           @ Increment pointer
    ldrb R7, [R2, R6]       @ Load new character
    b constLoop             @ Go to start of loop

  constEnd:
    mov pc, lr              @ Move back to callee

@ Result is stored in R4, stack is used to temporarily
@ store the value of R5 before calling expression.
term:
  sub sp, sp, #8            @ Allocate space in stack (#4 for value & #4 for lr)
  str lr, [sp]              @ Store lr in stack

  ldrb R7, [R2, R6]         @ Load the character
  cmp R7,#40                @ Compare with '('
  bne termElse              @ If not equal goto termElse (constant)
    add R6, R6, #1          @ Increment Pointer
    @@@ call expression
    str R5, [sp, #4]        @ Store the processed expression val in stack
    bl expression
    mov R4,R5               @ Store the val of mini-expression evaluated in R4
    ldr R5, [sp,#4]         @ Restore back the value in stack
    add R6, R6, #1          @ Increment the pointer
    b termEnd               @ Exit

  termElse:
    @@@ call constant
    bl constant             @ If not '('
    mov R4, R3              @ Then no., process it
  termEnd:
    ldr lr,[sp]             @ Restore the callee address
    add sp, sp, #8          @ Free the space
    mov pc,lr               @ Get back to callee


@ Result is stored in R4, stack is used to temporarily
@ store the value of R4 before calling any other function.
expression:
  sub sp, sp, #8            @ Create space in the stack
  str lr, [sp]              @ store the present link address in stack
  @@@call term
  str R4, [sp, #4]
  bl term
  mov R5, R4                @ Store the new processed value
  ldr R4, [sp, #4]          @ Store the previous value

  expLoop:                  @ The loop for operation
    ldrb R7,[R2, R6]        @ Load back the value
    cmp R7,#43              @ Check for addition
    beq addition

    cmp R7, #45             @ Check for subtraction
    beq subtract

    cmp R7, #42             @ Check for multiplication
    beq multiplication
    bne expressionEnd       @ If none then ')' expression complete

    addition:               @ Simple addition call
      add R6, R6, #1
      @@@ call term
      str R4, [sp, #4]
      bl term
      add R5, R5, R4
      ldr R4, [sp, #4]
      b expLoop

    subtract:               @ Simple subtraction call
      add R6, R6, #1
      @@@ call term
      str R4, [sp, #4]
      bl term
      sub R5, R5, R4
      ldr R4, [sp, #4]
      b expLoop

    multiplication:         @ Simple multiplication call
      add R6, R6, #1
      @@@ call term
      str R4, [sp, #4]
      bl term
      mul R8, R5, R4
      mov R5, R8
      ldr R4, [sp, #4]
      b expLoop

  expressionEnd:            @ Expression end
    ldr lr,[sp]             @ Go back to previous call
    add sp, sp, #8
    mov pc,lr



exit:
  mov R1, R5                @ move to output register
  swi SWI_PrInt             @ print
  swi SWI_Exit


  .data
  myExp: .asciz "31+12*20-18"   @ Describe the expression.
  .end
