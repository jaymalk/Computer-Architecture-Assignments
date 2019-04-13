.text
    ldr r5, =A
    mov r0, #255
    strb r0, [r5]
    ldrb r6, [r5]
    ldrsb r6,[r5]

    mov r4, r0, LSL #24
    str r4,[r5,#4]
    add r5,r5,#4
    ldrh r6,[r5,#2]
    ldrsh r6,[r5,#2]
    mov r0, #127
    mov r3, r0, LSL #16
    mov r0, #63
    mov r2, r0,  LSL #8
    mov r1, #31

    @ Setting
    eor r0, r1, r2
    eor r0, r0, r3
    eor r0, r0, r4
    @ mov r5, #100
    mov r6, #1
    str r0, [r5], r6, LSL #2
    str r1,[r5, r6, LSL #2]
    strb r1,[r5]
    strh r1,[r5, #2]
    @ Testing
    ldrb r1, [r5]
    ldrb r2, [r5, #1]
    ldrh r3, [r5, #2]
    ldrh r4, [r5]
    ldrsb r6,[r5]
    swi 0x11

.data
    A: .space 400

.end

@ Program No - 010 lab9 main.coe
@ E3A05064,E3A000FF,E5C50000,E5D56000,
@ E1D560D0,E1A04C00,E5854004,E2855004,
@ E1D560B2,E1D560F2,E3A0007F,E1A03800,
@ E3A0003F,E1A02400,E3A0101F,E0210002,
@ E0200003,E0200004,E3A06001,E6850106,
@ E7851106,E5C51000,E1C510B2,E5D51000,
@ E5D52001,E1D530B2,E1D540B0,E1D560D0,
