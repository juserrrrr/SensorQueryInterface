.include "memManagement.s"
.macro putLCDPinsOutput
    GPIOSetDirection output, pin_RS
    GPIOSetDirection output, pin_E
    GPIOSetDirection output, pin_D4
    GPIOSetDirection output, pin_D5
    GPIOSetDirection output, pin_D6
    GPIOSetDirection output, pin_D7
.endm

@ mov r10, 9 bits @r10 tem os bits de transmissao pro LCD
@ r9 faz a máscara pra pegar bit a bit
@ r8 é contador de 4 bits
@ r11 é para registrar o endereço base dos pinos (pin_rs)
instructionCode:
    ldr r11, =pin_RS
    and r9, r10, #1 @Mascara para pegar o menos significativo
    GPIOSet r11, r9 @Setagem do Pino RS
    lsr r10, #1
    mov r8, #1 @r8 é contador
    add
    
firstNibble:
    and r9, r10, #1 @Mascara para pegar o menos significativo
    GPIOSet pin_D4, r9 @Setagem do Pino 
    lsr r10, #1
    addi r8, r8, #1 @incremento o contador
    cmp r8, #4 @comparo com 4 o contador
    ble firstNibble
    enable

lastNibble:
    and r9, r10, #1 @Mascara para pegar o menos significativo
    GPIOSet pin_D4, r9 @Setagem do Pino 
    lsr r10, #1
    addi r8, r8, #1 @incremento o contador
    cmp r8, #4 @comparo com 4 o contador
    ble lastNibble
    enable
    bx lr
    
    
    
.macro instructionCode PD7, PD6, PD5, PD4
    GPIOSet pin_RS, low
    GPIOSet pin_D4, \PD4 
    GPIOSet pin_D5, \PD5
    GPIOSet pin_D6, \PD6
    GPIOSet pin_D7, \PD7

.endm


.macro dataCode PD7, PD6, PD5, PD4
    GPIOSet pin_RS, high
    GPIOSet pin_D4, \PD4
    GPIOSet pin_D5, \PD5 
    GPIOSet pin_D6, \PD6
    GPIOSet pin_D7, \PD7
.endm

.macro enable
    nanoSleep totalLoadingTimeRs
    GPIOSet pin_E, high
    nanoSleep totalEnableTimeHigh
    GPIOSet pin_E, low
    nanoSleep remainingEnableTime
.endm

.macro setSecondLine
    instructionCode high, high, low, low
    enable
    instructionCode low, low, low, low
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução
.endm

.macro returnHome
    instructionCode low, low, low, low
    enable
    instructionCode low, low, high, low
    enable
    nanoSleep awaitInstructionHome @ Espera o LCD processar a instrução de return home
.endm

.macro initialize

    nanoSleep zeMeMama
    instructionCode low, low, high, high
    enable

    nanoSleep zeMeMama2
    instructionCode low, low, high, high
    enable

    nanoSleep zeMeMama3
    instructionCode low, low, high, high
    enable
    @ ----------- 1 ----------- @
    instructionCode low, low, high, low @Function set inicialização, mudar para 4 bits
    enable @ Envia o sinal de enable para o LCD
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução
    @ ----------- 2 ----------- @
    instructionCode low, low, high, low @Function set código alto
    enable
    instructionCode low, high, low, low @Function set código baixo
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução
    @ ----------- 3 ----------- @
    instructionCode low, low, low, low @Display on/off código alto
    enable 
    instructionCode high, low, low, low @Display on/off código baixo
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução
    @clear display
    instructionCode low, low, low, low
    enable
    instructionCode low, low, low, high
    enable
    @ ----------- 4 ----------- @
    instructionCode low, low, low, low @ entry mode set código alto
    enable
    instructionCode low, high, high, low @ entry mode set código baixo
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução
.endm
