.extern expression, prints, fgets, itoa


.text

  
  loop:
    ldr R1, #80
    mov R2, #0
    ldr R0, =inputMessage
    bl prints
    mov R0,#0
    bl fgets
    cmp R0,#0
    beq exit
    ldr R2, R0             @ Load the expression in R2
    mov R5, #0             @stores the result of Expression function
    mov R6, #0             @position in string
    ldrb R7,[R2, R6]       @It is character in string
    mov R8, #0             @ Variable for multiplication storage
    mov R9, #10            @ For multiplication by 10

    bl expression
    ldr R0, =outputMessage
    bl prints
    ldr R0, R5
    ldr R1, =bufferSpace
    
    bl itoa
    bl prints

    bl loop


    

  exit:
    ldr R0, =exitMessage
    bl prints
    mov R0, #0x18
    mov R1, #0
    swi 0x12345

.data
    inputMessage: .asciz "Enter  an  expression  to  be  evaluated: "
    outputMessage: .asciz "Expression evaluates to: "
    exitMessage: .asciz "Exiting the program now."
    bufferSpace: .space 80

.end
 