@ Finds 15th power of 2
@ Program : 3(011)
.text
    mov r1, #1              @ For storing the result
    mov r2, #0              @ For storing the current Index
    mov r3, #1              @ Temporary variable
    mov r4, #15             @ Final result of power

loop: 
    cmp r2, r4
    beq exit
    add r1, r3, r3
    mov r3, r1
    add r2, r2, #1
    b loop

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