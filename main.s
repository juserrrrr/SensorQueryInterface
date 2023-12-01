.include "utils.s"
.include "codesLCD.s"

.section .text
.global _start
_start:
    @ mapMem
    @ nanoSleep oneSecond
    @ GPIOSetDirection output, pin_PA09
    @ putLCDPinsOutput @Seta os pinos do LCD como output
    @ mov r6, #15
    @ GPIOSet pin_D5, high
    @ B display
    @ B step
    ldr r9, =pin_D4
    ldr r10, =pin_D5
    ldr r11, =pin_D6
    ldr r12, =pin_D7

@loop: 
@    GPIOSet pin_PA09, high
@    nanoSleep oneSecond
@brk1:
@    GPIOSet pin_PA09, low
@    nanoSleep oneSecond
@    subs r6, #1
@    bne loop
display:
	
    initialize
    
    @ ----------- 5 ----------- @
    @Faz o L (0100 1100)
    dataCode low, high, low, low @ Bits mais altos
    enable
    dataCode high, high, low, low @ Bits mais baixos
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução
    
    
    @Escreve A (0100 0001)
    dataCode low, high, low, low
    enable
    dataCode low, low, low, high
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução

    @ ----------- 6 ----------- @

    setSecondLine @Pula pra próxima linha
    

    @ Escreve R (0101 0010)
    dataCode low, high, low, high
    enable
    dataCode low, low, high, low
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução

    @ Escreve A (0100 0001)
    dataCode low, high, low, low
    enable
    dataCode low, low, low, high
    enable
    nanoSleep awaitInstruction @ Espera o LCD processar a instrução

    @ ----------- 7 ----------- @
    returnHome
    

_end: 
    mov R0, #0 @ Use 0 return code
    mov R7, #1 @ Command code 1 terms
    svc 0 @ Linux command to terminate



