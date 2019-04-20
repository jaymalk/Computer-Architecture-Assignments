@ Code for testing unified memory

.text
    mov r0, #100
    mov r1, #10
    str r1, [r0]
    mov r1, #11
    ldr r1, [r0]