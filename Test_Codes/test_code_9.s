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

.data
    A: .space 400

.end
