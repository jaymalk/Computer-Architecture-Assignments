@ Sum of powers of two till index 16
@ Program : 4

.text
    mov r0, #0      @ Sum value
    mov r1, #1      @ Value at index
    mov r2, #0      @ Index of 2
    mov r3, #16     @ Final index value

loop:
    cmp r3, r1
    beq exit
    add r0, r1, r0
    add r1, r1, r1
    add r2, r2, 1
    b loop

exit:
    swi 0x11
    .end