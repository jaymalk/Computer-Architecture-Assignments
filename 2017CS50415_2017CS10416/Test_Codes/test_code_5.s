@ Sum of powers of 2 till index 10 (different method O(2^n))
@ Program : 5

.text
    mov r0, #0      @ Sum value
    mov r1, #1      @ Integer iteration (1 - 1024)
    mov r2, #0      @ Addend count
    mov r3, #0      @ Temporary hold

loop:
    cmp r2, #10
    beq exit
    sub r3, r1, #1          @ r3 = r1-1
    tst r3, r1              @ (r1)&&(r1-1)
    bne loop_end            @ Z set => power of 2
    add r0, r0, r1
    add r2, r2, #1

loop_end:
    add r1, r1, #1
    b loop 
   
exit:
    swi 0x11
    .end