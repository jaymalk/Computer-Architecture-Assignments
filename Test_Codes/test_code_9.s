.text
    mov r0, #255
    mov r4, r0, LSL #24
    mov r0, #127
    mov r3, r0, LSL #16
    mov r0, #63
    mov r2, r0,  LSL #8
    mov r1, #31

    @ Setting
    eor r0, r1, r2
    eor r0, r0, r3
    eor r0, r0, r4
    ldr r5, =A
    str r0, [r5]

    @ Testing
    ldrb r1, [r5]
    ldrb r2, [r5, #1]
    ldrh r3, [r5, #2]
    ldrh r4, [r5]
    swi 0x11

.data
    A: .space 400

.end

@ Program No - 010 lab9 main.coe
@ E3A000FF,E1A04C00,E3A0007F,E1A03800,
@ E3A0003F,E1A02400,E3A0101F,E0210002,
@ E0200003,E0200004,E3A05064,E5850000,
@ E5D51000,E5D52001,E1D530B2,E1D540B0,
