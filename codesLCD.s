.macro setLcdPins
    ldr r4, =pin_E
    mov r5, #output
    bl setDirectionGPIO

    ldr r4, =pin_RS
    mov r5, #output
    bl setDirectionGPIO

    ldr r4, =pin_D7
    mov r5, #output
    bl setDirectionGPIO

    ldr r4, =pin_D6
    mov r5, #output
    bl setDirectionGPIO

    ldr r4, =pin_D5
    mov r5, #output
    bl setDirectionGPIO

    ldr r4, =pin_D4
    mov r5, #output
    bl setDirectionGPIO
.endm

.macro setSecondLine
    mov r2, #0b111000000
    mov r3, #0
    bl instructionCode
.endm

.macro returnHome
    mov r2, #0b100000010
    mov r3, #0
    bl instructionCode
.endm

.macro shiftCursorRight
    mov r2, #0b100010100
    mov r3, #0
    bl instructionCode
.endm

.macro clearDisplay
    mov r2, #0b100000001
    mov r3, #0
    bl instructionCode
.endm

.macro initialize

    nanoSleep timerLcd1
    @Primeira parte da inicialização
    mov r2, #0b100110000
    mov r3, #0
    bl instructionCode
    nanoSleep timerLcd2

    @Segunda Parte da inicialização
    mov r2, #0b100110000
    mov r3, #1
    bl instructionCode
    nanoSleep timerLcd3

    @Terceira parte da inicialização
    mov r2, #0b100110000
    mov r3, #1
    bl instructionCode
    
    @Colocando como 4 bits
    mov r2, #0b100100000
    mov r3, #1
    bl instructionCode

    @Definindo interface
    mov r2, #0b100101100
    mov r3, #0
    bl instructionCode

    @display on/off mode
    mov r2, #0b100001100
    mov r3, #0
    bl instructionCode
    
    clearDisplay

    @mode set
    mov r2, #0b100000110
    mov r3, #0
    bl instructionCode

.endm

.macro enable
    ldr r1, =pin_E
    GPIOSet r1, #0
    nanoSleep totalLoadingTimeRs
    GPIOSet r1, #1
    nanoSleep totalEnableTimeHigh
    GPIOSet r1, #0
    nanoSleep remainingEnableTime
.endm

.macro writeDegrees
    mov r2, #0b011011111
    mov r3, #0
    bl instructionCode
.endm


@r3 é para sinalizar se é pra incialização, usando somente 4 bits, ou normal - 8 bits (1 inicialização, 0 - transmissão normal)
@ mov r2, 9 bits @r2 tem os bits de transmissao pro LCD
@ r9 faz a máscara pra pegar bit a bit
@ r6 é contador de 4 bits
@ r11 é para registrar o endereço base dos pinos (pin_rs)
instructionCode:
    push {r1, r6, r9}
    ldr r1, =pin_RS
    and r9, r2, #0b100000000 @Mascara para pegar o mais significativo
    lsr r9, #8 @Desloca para o bit menos significativo
    eor r9, r9, #0b1
    GPIOSet r1, r9 @Setagem do Pino RS
    lsl r2, #1
    mov r6, #1 @r10 é contador
    add r1, #0x10 @Vai do pin_RS para o pin_D4 no data
nibble:
    and r9, r2, #0b100000000 @Mascara para pegar o mais significativo
    lsr r9, #8 @Desloca para o bit menos significativo
    GPIOSet r1, r9 @Setagem do Pino 
    lsl r2, #1
    add r6, #1 @incremento o contador
    cmp r6, #4 @comparo com 4 o contador
    add r1, #0x10 @Vai de um pino para o próximo
    ble nibble
    enable
    cmp r3, #0
    beq resetPinValue
    pop {r1, r6, r9}
    bx lr
resetPinValue:
    ldr r1, =pin_D7 @restaura o valor do endereço para o pin_D4
    mov r6, #1
    mov r3, #1
    b nibble
    
    
writeString:
    push {lr}
    clearDisplay
    nanoSleep awaitInstructionHome
loopWrite:
    ldrb r2, [r5]
    mov r3, #0
    cmp r2, #10 @decimal do valor ascii de \n
    beq writeSecondLine
    cmp r2, #0 @decimal do valor ascii de \0
    beq endWrite
    
    cmp r2, #42 @decimal do valor ascii de *
    beq degreesWrite
    
    bl instructionCode
    add r5, #0x1
    b loopWrite
writeSecondLine:
    setSecondLine
    add r5, #0x1
    b loopWrite
degreesWrite:
    writeDegrees
    add r5, #0x1
    b loopWrite
endWrite:
    pop {pc}
    bx lr