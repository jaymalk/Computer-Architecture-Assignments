@ Decimal to Binary conversion (53 -> 110101) (i.e. the final decimal value represents the binary form of given decimal)
@ Program : 6

.text
    mov r0, #0          @ Final Value
    mov r1, #53         @ Decimal Value (constraint: must be less than 1000) 
    mov r2, #0          @ Shifting done so far (===) Index of power
    mov r3, #1          @ Powers of two
    mov r4, #1          @ Powers of ten
    mov r5, #0          @ Temp. variable
loop:
    cmp r1, #0          @ Value processed ==> exit
    beq exit
    and r5, r3, r1      @ Check if bit at index 'r2' is 1
    cmp r5, r3          @ r5 must be equal to r3 if true
    bne back            @ If true then add r4 = pow(10, r2) to r0
    add r0, r0, r4      @ Adding the power of ten (r0 += r4)
    sub r1, r1, r3      @ Subtracting the original value (r3) from r1
back:
    mov r5, #0
    mov r6, #0          @ Multiplication by 10
mult_ten:                   @ --
    cmp r5, #10             @ --
    beq skip                @ --
    add r6, r6, r4          @ --
    add r5, r5, #1          @ --
    b mult_ten              @ --
skip:
    mov r4, r6          @ r4 = r4*10
    add r2, r2, #1      @ Increment index by 1 (r2 += 1)
    add r3, r3, r3      @ r2 = r3*2 (maintaining r3 = pow(10m, r2))
    b loop
exit: