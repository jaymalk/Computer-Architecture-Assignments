@@@ Find sum of array elements
	.text
@ Writing to the array
	mov r1, #1
	mov r2, #100		@ Starting address of the array
Lab1:
	str r1, [r2, #0]		@ Stores i at array[i]
	add r2, r2, #4		@ Pointing to next element 
	add r1, r1, #1
	cmp r1, #11		@ Loop termination check
	bne Lab1

@ Reading from the array
	mov r3, #0			@ Initialize sum
	mov r2, #100		@ Initialize address pointer
Lab2:
	sub r1, r1, #1
	cmp r1, #0			@ Loop termination check
	beq Over
	ldr r4, [r2, #0]		@ array[i] is read
	add r3, r3, r4		@ Add to the sum
	add r2, r2, #4		@ Pointing to next element 
	b Lab2
Over:
	.end

