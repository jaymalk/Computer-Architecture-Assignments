@ A program which tests all DP instructions
@ Program : 1
.text
    mov r1, #255               @ 8-1  ONEs
    mov r2, r1, LSL #8         @ 16-9 ONEs
    orr r4, r1, r2             @ 16-1 ONEs
    eor r5, r4, r4, LSL #16    @ ALL  ONEs
    mov r3, #1                 @ Single one, throughout
loop:
    mvn r3, r3
    eor r6, r2, r1
    eor r7, r5, r6
    mov r1, r1, LSL #1
    mov r2, r2, LSR #1
    cmn r3, #129
    beq exit
    bic r3, r5, r3, ROR #31
    b loop
exit:
    swi 0x11



@ E3A010FF,E1A02401,E1814002,E0245804,
@ E3A03001,E1E03003,E0226001,E0257006,
@ E1A01081,E1A020A2,E3730081,0A000001,
@ E1C53FE3,EAFFFFF6,