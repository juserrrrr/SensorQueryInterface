escolhaSensorComando:
    push {r1, r2, r3, r4, r5, r6, r7, r9, lr}
    mov r4, #0 @Incialmente escolhe o sensor (r4=0)
    mov r5, #0b00110000 @Valor inicial da contagem é 0

setCursor:
    cmp r4, #0 
    beq cursorSensor @Se for para o sensor
    b cursorComando @Se for para o comndo

cursorSensor:
    mov r7, #0b00110111 @(Máximo de sensor: 7)
    mov r2, #0b110001000 @Mover cursor para escolha do Sensor
    mov r3, #0
    bl instructionCode
    b loopBotaoSensorComando @pula para o loop dos botões

cursorComando:
    mov r7, #0b00110110 @(Máximo de comando: 6)
    mov r2, #0b111001100 @Mover cursor para escolha do comando
    mov r3, #0
    bl instructionCode

loopBotaoSensorComando:

    bl getUart
    
    ldr r1, =pin_BTN1
    GPIOGet r1
    cmp r0, #0 @Se botão de incremento pressionado
    beq incrementar
    
    ldr r1, =pin_BTN0
    GPIOGet r1
    cmp r0, #0 @Se botão de decremento pressionado
    beq decrementar
    
    ldr r1, =pin_BTN2
    GPIOGet r1
    cmp r0, #0 @Se botão de enter pressionado
    beq enter

    b loopBotaoSensorComando

incrementar:
    cmp r5, r7 @comparo com o máximo 
    beq setCursor @ se for 7, não incrementa só volta para o loop
    add r5, #1 @incremento 1
    mov r3, #0
    mov r2, r5
    bl instructionCode @Escrevo o número
    ldr r1, =pin_BTN1
    bl debouncerLoop @DEBOUNCER PARA O BOTÃO
    b setCursor @loop de contagem do sensor
    
decrementar:
    cmp r5, #0b00110000 @comparo com o 0 ascii
    beq setCursor @ se for 0, não decrementa só volta para o loop
    sub r5, #1 @decremento 1
    mov r3, #0
    mov r2, r5
    bl instructionCode @Escreve o número
    ldr r1, =pin_BTN0
    bl debouncerLoop @DEBOUNCER PARA O BOTÃO
    b setCursor
    
enter:
    add r4, #1
    cmp r4, #1 @Se for 1, vou para o comando
    beq carregaSensor
    
    cmp r4, #2
    beq endEscolhaSensorComando

carregaSensor:
    ldr r6, =sensorEscolhido
    and r5, r5, #0b1111
    str r5, [r6] @Salvo valor do sensor na memória
    mov r5, #0b00110000 @(reinicio o valor de r5)
    ldr r1, =pin_BTN2
    bl debouncerLoop @DEBOUNCER PARA O BOTÃO
    b setCursor @Volto pro loop

endEscolhaSensorComando:
    ldr r6, =comandoEscolhido
    and r5, r5, #0b1111
    str r5, [r6] @Salvo valor do comando na memória
    ldr r1, =pin_BTN2
    bl debouncerLoop @DEBOUNCER PARA O BOTÃO
    pop {r1, r2, r3, r4, r5, r6, r7, r9, pc}

telas:
    push {lr}
    @bl getUart

    clearDisplay @Limpa o display
    returnHome @retorna o cursor a 0
    nanoSleep awaitInstructionHome

    ldr r5, =tela_teste
    bl writeString @Escreve a tela teste
    bl escolhaSensorComando @salto para esta label
    pop {pc}