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


@ Configurações iniciais da uart
@ Para um clock de 700Mhz e uma baud rate de 9600
@ Usando a fórmula do datasheet, o valor é 4557: 1000111001101
uartSetup:
    ldr r9, =uart3_base         @ carregando o endereço base da uart3

    @ permitindo a manipulação da baud rate do registrador lcr (dll e dlh)
    mov r11, #1             
    lsl r11, #lcr_dlab          @ preparando o valor que permite a manipulação

    @ setando os 8 bits como padrão
    mov r10, #0b11
    lsl r10, #lcr_dls
    orr r12, r10, r11

    @ salvando as configurações na memória
    str r12, [r9, #uart_lcr]

    @ setando a baud rate
    mov r11, #0b11001101        @ lower 8 bits do valor calculado
    str r11, [r9, #uart_dll]    @ salvando na memória

    mov r11, #0b10001           @ higher 8 bits do valor calculado
    str r11, [r9, #uart_dlh]    @ salvando na memória

    @ proibindo a manipulação do dll e dlh e liberando a uart
    mov r11, #1             
    lsl r11, #lcr_dlab          
    mvn r11, r11                @ preparando o valor que proibe a manipulação
    and r12, r12, r11
    str r12, [r9, #uart_lcr]    @ salvando as configurações na memória


@ Valor a ser enviado: r12
@ Faz uma tentativa de enviar um valor pela uart
sendUart:
    ldr r9, [=uart3_base, uart_lsr]         @ carregando o registrador do lsr
    lsr r9, #lsr_thre           @ jogando o bit de verificação para a primeira posição
    mov r10, #1                 @ máscara para pegar o primeiro bit

    and r10, r9, r10           
    cmp r10, #0

    beq sendUart            @ caso o envio não esteja liberado, loop

    str r12, [r9, #uart_thr]     @ envia o valor de r12 pela uart

end_sendUart:
    bx lr

@ Lê a uart e
@ Salva no .data currentInfo, na ordem endereço, comando, valor
readUart:
    ldr r9, [=uart3_base, uart_lsr]         @ carregando o registrador do lsr
    lsr r9, #lsr_dr           @ jogando o bit de verificação para a primeira posição
    mov r10, #1                 @ máscara para pegar o primeiro bit

    and r10, r9, r10           
    cmp r10, #0

    beq end_readUart            @ caso não tenha caractere para ser lido, fim da função

    ldr r12, [=uart3_base, #uart_thr]    @ salva o valor que veio pela uart no r12 (endereço)

    ldr r8, =currentInfo    @ endereço da currentInfo
    str r12, [r8]     @ guarda o valor do endereço na currentInfo

    mov r11, #1                  @ contador para ler os outros 2 bytes

readRemaining:
    cmp r11, #3
    beq end_readUart                    @ se o contador = 3, todos os bytes foram lidos

    ldr r9, [=uart3_base, uart_lsr]         @ carregando o registrador do lsr
    lsr r9, #lsr_dr                         @ jogando o bit de verificação para a primeira posição
    mov r10, #1                             @ máscara para pegar o primeiro bit

    and r10, r9, r10           
    cmp r10, #0
    beq readRemaining                       @ caso não tenha caractere para ser lido, loop até chegar

    add r11, r11, #1                @ somando 1 ao contador

    ldr r12, [=uart3_base, #uart_thr]    @ salva o valor que veio pela uart no r12 (endereço)

    add r8, r8, #4                  @ indo para o proximo índice na currentInfo
    str r12, [=r8]     @ guarda o valor do endereço na currentInfo

end_readUart:
    bx lr


