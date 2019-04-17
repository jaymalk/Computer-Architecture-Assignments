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