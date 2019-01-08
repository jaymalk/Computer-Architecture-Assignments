@@@ READ AND EVALUATE ARITHMETIC EXPRESSION
@@@ Paralled with the c code for the same problem

  .equ SWI_PrInt, 0x6b  @ Write an Integer
  .equ Stdout, 1        @ Set output mode to be Output View
  .equ SWI_Exit, 0x11   @ Stop execution

  .text

  mov R0, #Stdout        @ Set the output mode
  ldr R2, =myExp         @ Load the expression
  mov R3, #0             @ Position/Index in the String array
  mov R4, #0             @ Final Answer
  mov R5, #0             @ Variable to process each number
  mov R6, #0             @ Keep the check of each operation
  mov R8, #0             @ Variable for multiplication storage
  mov R9, #10            @ For multiplication by 10

@@@== START (MAIN) =============================================
start:
  ldrb R7, [R2, R3]      @ Get the character
  cmp R7, #48            @ Check if Integer
  bge number
  b operation

@@@== PROCESS THE INPUT IF NUMBER ==============================
number:
  mul R8, R5, R9
  mov R5, R8
  sub R7, R7, #48
  add R5, R5, R7
  add R3, R3, #1          @ Increment the index
  b start

@@@== PROCESS THE INPUT IF AN OPERATION ========================
operation:
  cmp R6, #0              @ Compare the last operation
  addeq R4, R4, R5
  subgt R4, R4, R5
  bge no_multiply
  mul R8, R4, R5
  mov R4, R8
no_multiply:
  mov R5, #0
  cmp R7, #0              @ Exit if the literal is end
  beq exit
  cmp R7, #43		  @ Otherwise compare operations
  beq add
  cmp R7, #42
  beq multiply
  cmp R7, #45
  beq subtract

add:
  mov R6, #0
  b end

multiply:
  mov R6, #-1
  b end

subtract:
  mov R6, #1
  b end

end:
  add R3, R3, #1
  b start

@@@== EXIT AND PRINT ===========================================
exit:
  mov R1, R4
  swi SWI_PrInt
  swi SWI_Exit

@@@== DATA =====================================================
  .data
  myExp: .asciz "31+12*20-18"   @ Describe the expression.
  .end
