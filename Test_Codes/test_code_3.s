@ Finds Nth power of P
@ Program : 3(011)
.text
    mov r0, #15         @ P = 15
    mov r1, #2          @ N = 2
    mov r2, #1          @ Answer
loop:
    cmp r0, #0
    beq exit
    and r1, r0, #1
    cmp r1, #1
    muleq r3, r2, r1
    mov r2, r3
    mul r3, r1, r1
    mov r1, r3
    mov r0, r0, RSL #1

exit:
    swi 0x11
    .end



@ E3A01001
@ E3A02000
@ E3A03001
@ E3A0400F
@ E1520004
@ 0A000003
@ E0813003
@ E1A03001
@ E2822001
@ EAFFFFF9
@ EF000011