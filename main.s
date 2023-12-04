.include "utils.s"
.include "codesLCD.s"
.include "memManagement.s"

.section .text
.global _start
_start:
    mapMem
    nanoSleep oneSecond
    @ GPIOSetDirection output, pin_PA09
    putLCDPinsOutput @Seta os pinos do LCD como output
    @ mov r6, #15
    @ GPIOSet pin_D5, high
    B display
    @ B step

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
    mov r10, #76
    mov r12, #0
    bl instructionCode

    @Escreve A (0100 0001)
    mov r10, #65
    mov r12, #0
    bl instructionCode

    setSecondLine @Pula pra próxima linha
    
    @ Escreve R (0101 0010)
    mov r10, #82
    mov r12, #0
    bl instructionCode

    @ Escreve A (0100 0001)
    mov r10, #65
    mov r12, #0
    bl instructionCode

    @ ----------- 7 ----------- @
    returnHome
    

_end: 
    mov R0, #0 @ Use 0 return code
    mov R7, #1 @ Command code 1 terms
    svc 0 @ Linux command to terminate



