.extern expression

    .equ SWI_Open, 0x66        @open a file
    .equ SWI_Close,0x68        @close a file
    .equ SWI_PrChr,0x00        @ Write an ASCII char to Stdout
    .equ SWI_PrInt,0x6b        @ Write an Integer
    .equ SWI_PrStr, 0x69       @ Write a null-ending string 
    .equ Stdout,  1            @ Set output target to be Stdout
    .equ SWI_Exit, 0x11        @ Stop execution
    .equ SWI_RdStr, 0x6a       @ Read String

.text
    _start:
        @ Input the expression file
        ldr r0,=InFileName
        mov r1,#0
        swi SWI_Open

        ldr r1,=InputFileHandle   @ if OK, load input file handle
        str r0,[r1]               @ save the file handle

@ == Read integers until end of file =============================
RLoop:
ldr r0,=InputFileHandle   @ load input file handle
ldr r1,=CharArray
mov r2, #80
ldr r0,[r0]
swi SWI_RdStr             @ read the integer into R0
bcs _exit       @ Check Carry-Bit (C): if= 1 then EOF reached
@ print the integer to Stdout
mov r11, r1
mov R0,#Stdout            @ target is Stdout
swi SWI_PrStr
mov R0,#Stdout            @ print new line
ldr r1, =ans
swi SWI_PrStr
        mov r2, r11
        mov r5, #0
        mov r6, #0
        ldrb r7, [r2, r6]
        mov r8, #0
        mov r9, #10
        bl expression
        mov r1, r5
        swi SWI_PrInt
        mov R0,#Stdout            @ print new line
ldr r1, =NL
swi SWI_PrStr
bal RLoop                 @ keep reading till end of fil



        mov r2, r1
        mov r5, #0
        mov r6, #0
        ldrb r7, [r2, r6]
        mov r8, #0
        mov r9, #10
        bl expression
        mov r1, r5
        @ mov r0, #Stdout
        @ swi SWI_PrInt
        @ bcs _exit
        @ b _loop

    @     ldr r0,=InputFileHandle
    @     mov r2, #100
    @     swi SWI_RdStr
    @     mov r0, #Stdout
    @     swi SWI_PrStr

        @ mov r2, r1
        @ mov r5, #0
        @ mov r6, #0
        @ ldrb r7, [r2, r6]
        @ mov r8, #0
        @ mov r9, #10
        @ bl expression
        @ mov r1, r5
        @ mov r0, #Stdout
        @ swi SWI_PrInt

    _exit:
        mov r0, #Stdout
        ldr r1,=end
        swi SWI_PrStr

.data
.align
    InputFileHandle:   .skip  1000
    CharArray:         .skip  80
    InFileName:        .asciz "expr.txt"
    FileOpenInpErrMsg: .asciz "Failed to open input file \n"
    EndOfFileMsg:      .asciz "End"
    ColonSpace:        .asciz " : "
    ans:               .asciz "\nAnswer : "
    end:               .asciz "Thanks"
    NL:                .asciz "\n"
.end