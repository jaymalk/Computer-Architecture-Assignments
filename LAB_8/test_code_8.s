@ Illustration on bit implementation using logical operatos
@ Program : 8

.text
    mov r1, #31
    mov r1, r1, LSL #11
    mov r2, #31
    mov r0, #0
    mov r3, #0
loop:
    cmp r0, #16
    beq exit
    add r0, r0, #1
    eor r3, r1, r2
    mov r2, r2, LSL #1
    mov r1, r1, LSR #1
    b loop
exit:
    swi 0x11
    .end



@ E3A0101F
@ E1A01581
@ E3A0201F
@ E3A00000
@ E3A03000
@ E3500010
@ 0A000004
@ E2800001
@ E0213002
@ E1A02082
@ E1A010A1
@ EAFFFFF8