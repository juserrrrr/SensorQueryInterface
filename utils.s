@ Macro para aguardar um tempo em segundos e nanosegundos
@ R0 = Tempo em segundos
@ R1 = Tempo em nanosegundos
.macro nanoSleep time
  push {r0, r1, r7}
  ldr r0, =\time
  add r1, r0, #4  
  mov r7, #sys_nanosleep
  svc 0
  pop {r0, r1, r7}
.endm


.macro setBtnsPins
  push {r4, r5}

  ldr r4, =pin_BTN0
  mov r5, #input
  bl setDirectionGPIO
  
  ldr r4, =pin_BTN1
  mov r5, #input
  bl setDirectionGPIO

  ldr r4, =pin_BTN2
  mov r5, #input
  bl setDirectionGPIO

  pop {r4, r5}
.endm


@ r1: endereço na memoria do botão
debouncerLoop:
  push {r0}
	cmp r0, #1
	beq notPressed
loopDeb:
	nanoSleep fiveMilliSeconds
  GPIOGet r1   
	cmp r0, #0
	beq loopDeb
notPressed:
  pop {r0}
	bx lr

@R4: Valor a ser transformado em 2 ASCII
convertBinaryToAscii: 
    push {r4,r5,r6, lr}
    mov r6, #10
    udiv r5,r4,r6
    mul r6, r5, r6
    sub r4, r4, r6
    add r0, r5, #0b00110000
    add r1, r4,#0b00110000
    pop {r4, r5, r6, pc}