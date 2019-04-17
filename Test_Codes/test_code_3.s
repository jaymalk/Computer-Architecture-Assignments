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
    mov r0, r0, LSR #1
    b loop
exit:
    swi 0x11
    .end


@ LAB11 010
@ E3A0000F,E3A01002,E3A02001,E3500000,
@ 0A000007,E2001001,E3510001,00030192,
@ E1A02003,E0030191,E1A01003,E1A000A0,
@ EAFFFFF5,
