.include "memManagement.s"
.macro putLCDPinsOutput
    GPIOSetDirection output, pin_RS
    GPIOSetDirection output, pin_E
    GPIOSetDirection output, pin_D4
    GPIOSetDirection output, pin_D5
    GPIOSetDirection output, pin_D6
    GPIOSetDirection output, pin_D7
.endm

@r12 é para sinalizar se é pra incialização, usando somente 4 bits, ou normal - 8 bits (1 inicialização, 0 - transmissão normal)
@ mov r10, 9 bits @r10 tem os bits de transmissao pro LCD
@ r9 faz a máscara pra pegar bit a bit
@ r8 é contador de 4 bits
@ r11 é para registrar o endereço base dos pinos (pin_rs)
instructionCode:
    ldr r11, =pin_RS
    and r9, r10, #0b100000000 @Mascara para pegar o mais significativo
    mvn r9, r9
    GPIOSet r11, r9 @Setagem do Pino RS
    lsr r10, #1
    mov r8, #1 @r8 é contador
    add r11, 0x10 @Vai do pin_RS para o pin_D4 no data
    
firstNibble:
    and r9, r10, #0b100000000 @Mascara para pegar o mais significativo
    GPIOSet r11, r9 @Setagem do Pino 
    lsr r10, #1
    addi r8, r8, #1 @incremento o contador
    cmp r8, #4 @comparo com 4 o contador
    add r11, 0x10 @Vai de um pino para o próximo
    ble firstNibble
    enable
    sub r11, 0x40 @restaura o valor do endereço para o pin_D4
    cmp r12, #0
    beq lastNibble
    bx lr
    
lastNibble:
    and r9, r10, #1 @Mascara para pegar o menos significativo
    GPIOSet pin_D4, r9 @Setagem do Pino 
    lsr r10, #1
    add r8, r8, #1 @incremento o contador
    cmp r8, #4 @comparo com 4 o contador
    add r11, 0x10 @Vai de um pino para o próximo
    ble lastNibble
    enable
    bx lr

.macro enable
    nanoSleep totalLoadingTimeRs
    GPIOSet pin_E, high
    nanoSleep totalEnableTimeHigh
    GPIOSet pin_E, low
    nanoSleep remainingEnableTime
.endm

.macro setSecondLine
    mov r10, #0b111000000
    bl instructionCode
.endm

.macro returnHome
    mov r10, #0b100000010
    bl instructionCode
.endm

.macro initialize

    nanoSleep zeMeMama
    mov r10, #0b10011
    mov r12, #1
    bl instructionCode
    
    nanoSleep zeMeMama2
    bl instructionCode

    nanoSleep zeMeMama3
    bl instructionCode
    
    mov r10, #0b10010
    mov r12, #1
    bl instructionCode

    mov r10, #0b100101000
    mov r12, #1
    bl instructionCode

    mov r10, #0b100001000
    mov r12, #1
    bl instructionCode
    
    @clear display
    mov r10, #0b100000001
    mov r12, #1
    bl instructionCode
    
    mov r10, #0b100000110
    mov r12, #1
    bl instructionCode
.endm
