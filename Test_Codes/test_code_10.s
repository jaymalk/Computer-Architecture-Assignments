mov r0,#15
mul r1,r0,r0
mla r2,r0,r0,r1
mov r3, r0, LSL #28
smull r4,r5,r0,r3
umull r6,r7,r0,r3
smlal r4,r5,r0,r3
umlal r6,r7,r0,r3
mov r1, #0
mul r2,r1,r0
mov r3,#0
mov pc,lr

@ Lab 10 main.coe code -001
@ E3A0000F,E0010090,E0221090,E1A03E00,
@ E0C54390,E0876390,E0E54390,E0A76390,