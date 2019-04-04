@ Finding the factorial of n (10)
@ Program : 7

.text
    mov r0, #1      @ Answer
    mov r1, #1      @ Integer iterator
    mov r2, #6      @ The value of 'n'

fact_loop:          @ Factorial loop
    mov r5, #0      @ Multiply iterator
    mov r6, #0      @ Multiply value
    cmp r1, r2      @ Compare iterator for exit
    beq exit

    @ Starting multiplication
multiply:
    cmp r5, r1      @ Multiply
    beq complete    @ --
    add r6, r6, r0  @ --
    add r5, r5, #1  @ --
    b multiply      @ --

complete:
    mov r0, r6      @ Put value in ans
    add r1, r1, #1  @ Increment iterator
    b fact_loop     @ Go back to loop

exit: