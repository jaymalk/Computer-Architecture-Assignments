
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
  mov R3, #0    
  
  constLoop:  
    ldrb R7,[R2, R6]  
    cmp R7,#47
    ble constEnd
    cmp R7,#58
    bge constEnd

    mul R8, R3, R9
    mov R3, R8
    add R3, R3, R7
    sub R3, R3, #48
    add R6,R6, #1
    ldrb R7, [R2, R6]
    b constLoop

  constEnd:
    mov pc, lr

@ Result is stored in R4, stack is used to temporarily
@ store the value of R5 before calling expression.
term:
  sub sp, sp, #8
  str lr, [sp]
  
  ldrb R7, [R2, R6]
  cmp R7,#40
  bne termElse
    add R6, R6, #1
    @@@ call expression
    str R5, [sp, #4]
    bl expression
    mov R4,R5
    ldr R5, [sp,#4]
    add R6, R6, #1
    b termEnd

  termElse:
    @@@ call constant
    bl constant
    mov R4, R3
  termEnd:
    ldr lr,[sp]
    add sp, sp, #8
    mov pc,lr


@ Result is stored in R4, stack is used to temporarily
@ store the value of R4 before calling any other function.
expression:
  sub sp, sp, #8
  str lr, [sp]
  @@@call term
  str R4, [sp, #4]
  bl term
  mov R5, R4
  ldr R4, [sp, #4]

  expLoop:
    ldrb R7,[R2, R6]
    cmp R7,#43
    beq addition
    
    cmp R7, #45
    beq subtract
    
    cmp R7, #42
    beq multiplication
    bne expressionEnd

    addition:
      add R6, R6, #1
      @@@ call term
      str R4, [sp, #4]
      bl term
      add R5, R5, R4
      ldr R4, [sp, #4]
      b expLoop
    
    subtract:
      add R6, R6, #1
      @@@ call term
      str R4, [sp, #4]
      bl term
      sub R5, R5, R4
      ldr R4, [sp, #4]
      b expLoop
    
    multiplication:
      add R6, R6, #1
      @@@ call term
      str R4, [sp, #4]
      bl term
      mul R8, R5, R4
      mov R5, R8
      ldr R4, [sp, #4]
      b expLoop

  expressionEnd:
    ldr lr,[sp]
    add sp, sp, #8
    mov pc,lr



exit:
  mov R1, R5
  swi SWI_PrInt
  swi SWI_Exit


  .data
  myExp: .asciz "31+12*20-18"   @ Describe the expression.
  .end
