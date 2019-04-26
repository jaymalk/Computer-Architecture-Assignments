@ Fibbonaci (Better)
@ Program : 2(001)
.text
    mov r0, #10
    mov r1, #0
    mov r2, #1

loop:
    cmp r0, #0
    addne r2, r1, r2
    subne r1, r2, r1
    moveq pc, lr
    sub r0, r0, #1
    bl loop
    b exit
exit:
    swi 0x11
    .end


@ lAB11 011
@ E3A0000A,E3A01000,E3A02001,E3500000
@ 10812002,10421001,01A0F00E,E2400001
@ EBFFFFF9,EAFFFFFF,