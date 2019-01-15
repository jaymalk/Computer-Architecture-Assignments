.extern expression

    .equ SWI_Open, 0x66        @open a file
    .equ SWI_PrInt,0x6b        @ Write an Integer
    .equ SWI_PrStr, 0x69       @ Write a null-ending string 
    .equ Stdout,  1            @ Set output target to be Stdout
    .equ SWI_Exit, 0x11        @ Stop execution
    .equ SWI_RdStr, 0x6a       @ Read String

.text
    _start:
        ldr r0,=InFileName                      @ Input the file
        mov r1,#0                               @ Set mode to open
        swi SWI_Open                            @ Open file

        ldr r1,=InputFileHandle                 @ Store the file handle
        str r0,[r1]


    ReadLoop:
        @ Loop till EOF

        ldr r0,=InputFileHandle                 
        ldr r1,=CharArray                       @ Load the address
        mov r2, #80                             @ Provide data limit
        ldr r0,[r0]                             @ Load the handle
        swi SWI_RdStr                           @ Read String (Line)
        bcs _exit                               @ Exit if EOF

        mov r11, r1                             @ Store string for expression
        mov R0,#Stdout                          @ Change to output mode
        swi SWI_PrStr                           @ Print expression
        ldr r1, =ANS
        swi SWI_PrStr
            @ Preset for expression call

            mov r2, r11                         @ Reload expression stored before
            mov r5, #0
            mov r6, #0
            ldrb r7, [r2, r6]
            mov r8, #0
            mov r9, #10
            bl expression                       @ Call expression
            mov r1, r5                          @ Move answer to R1
        swi SWI_PrInt                           @ Print answer
        mov R0,#Stdout
        ldr r1, =NL
        swi SWI_PrStr
        swi SWI_PrStr
        bal ReadLoop                            @ Loop back



    _exit:
    @ Print exit statement
    
        mov r0, #Stdout
        ldr r1,=EOF
        swi SWI_PrStr

.data
.align
    InputFileHandle:   .skip  10000
    CharArray:         .skip  100
    InFileName:        .asciz "expr.txt"
    FileOpenInpErrMsg: .asciz "Failed to open input file \n"
    ColonSpace:        .asciz " : "
    ANS:               .asciz "\nAnswer : "
    EOF:               .asciz "End of File"
    NL:                .asciz "\n"
.end