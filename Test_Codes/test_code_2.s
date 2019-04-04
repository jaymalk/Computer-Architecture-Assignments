@ Fibonacci 10 : 55
@ Program : 2(001)
.text
    mov r1, #0
    mov r2, #1
    mov r3, #0
    mov r4, #10

loop: 
    cmp r4, #0
    beq exit
    add r3, r1, r2
    mov r1, r2
    mov r2, r3
    sub r4, r4, #1
    b loop

exit:
    swi 0x11
    .end



@ E3A01000
@ E3A02001
@ E3A03000
@ E3A0400A
@ E3540000
@ 0A000004
@ E0813002
@ E1A01002
@ E1A02003
@ E2444001
@ EAFFFFF8
@ EF000011