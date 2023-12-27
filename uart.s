.macro setUartPins
	ldr r4, =uart_tx
	mov r5, #uart3
	bl setDirectionGPIO

	ldr r4, =uart_rx
	mov r5, #uart3
	bl setDirectionGPIO
.endm


.macro configCcu
	ldr r1, [r12, #0x006C] @ carregando do endereco  do bus_clk
	mov r2, #1 
	lsl r2, #19 @ bit do uart3 gating
	orr r1, r2
	str r1, [r12, #0x006C] @ setando o uart3 gating em 1
	
	ldr r1, [r12, #0x0028] @ carregando do endereco  do pll_ph0
	mov r2, #1 
	lsl r2, #31 @ bit do enable (setando clk da uart em 600mhz)
	orr r1, r2
	str r1, [r12, #0x0028] @ setando o enable do pll_ph0 em 1
	
	ldr r1, [r12, #0x0058] @ carregando do endereco do apb2
	mov r2, #0b11
	lsl r2, #24 @ máscara no bit do clk_src
	bic r1, r2
	orr r1, r2
	str r2, [r12, #0x0058] @ setando o clk_src para o pll_ph0

	ldr r1, [r12, #0x02D8] @ carregando do endereco  do bus_soft
	mov r2, #1
	lsl r2, #19 @ bit do uart3_rst
	bic r1, r2 @ zerando o bit do uart3_rst, ligando o reset
	str r1, [r12, #0x02D8] @ aplicando configuracoes	

	ldr r1, [r12, #0x02D8] @ carregando do endereco  do bus_soft
	mov r2, #1 
	lsl r2, #19 @ bit do uart3_rst
	orr r1, r2
	str r1, [r12, #0x02D8] @ setando o uart3_rst para de-assert, desligando o reset
.endm

.macro configUart
	mov r1, #0b111	@ ativando fifo e resetando
	str r1, [r11, #0x08] @ ativando fcr[0] [1] e [2] (fifo e rst do fifo)

	
	ldr r2, [r11, #0x00C] @ carregando do endereco  do uart_lcr
	mov r1, #1 
	lsl r1, #7 @ bit do dlab (permitindo config de baud rate)
	orr r2, r1
	str r2, [r11, #0x00C] @ aplicando configuracoes

	
	mov r1, #0b01000010 	@ 8 bits de baixo do divisor da baud rate
	str r1, [r11]		@ setando o dll (offset do dll é 0, vai direto no r11)

	mov r1, #0b00001111	@ 8 bits de cima do divisor da baud rate
	str r1, [r11, #0x04]		@ setando o dlh

	ldr r2, [r11, #0x0C] @ carregando do endereco do uart_lcr
	mov r1, #1
	lsl r1, #7 @ bit do dlab
	bic r2, r1 @ zerando o bit do dlab permitindo a utilizacao da uart
	str r2, [r11, #0x0C] @ aplicando configuracoes	
	
	ldr r2, [r11, #0x00C] @ carregando do endereco  do uart_lcr
	mov r1, #11		  @ ativando os 8 bits como padrao
	orr r2, r1
	str r2, [r11, #0x00C] @ aplicando configuracoes
	
.endm

setGatingOn:
	push {r1, r2}
	ldr r1, [r12, #0x006C] @ carregando do endereco  do bus_clk
	mov r2, #1 
	lsl r2, #19 @ bit do uart3 gating
	orr r1, r2
	str r1, [r12, #0x006C] @ setando o uart3 gating em 1
	pop {r1, r2}
	bx lr


@ r5: valor que será enviado
@ r11: mapeamento da uart
sendUart:
	str r5, [r11] @ enviando valor pela uart	
	bx lr


getUart:
	push {r0, r1, r2, r3, r5, r6, r7}


	ldr r1, [r11, #0x0014] @ carregando do endereco  do uart_lsr
	mov r0, #1
	and r0, r1, r0		@ checando se o primeiro valor é 1 (Data Ready)
	cmp r0, #1		@ checando se o primeiro valor é 1 (Data Ready)

	beq getAddress	@ indo pegar o endereco recebido

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr

getAddress:

	ldr r5, [r11]	@ resgatando o endereco recebido

	nanoSleep awaitResponseUart @ aguardando atualizacao

	@b getCommand

getCommand:
	ldr r1, [r11, #0x0014] @ carregando do endereco  do uart_lsr
	mov r0, #1
	and r0, r1, r0		@ checando se o primeiro valor é 1 (Data Ready)

	cmp r0, #0		@ checando se o primeiro valor é 0 (Data Not Ready)
	beq getCommand @ loop enquanto o comando nao foi lido

	ldr r6, [r11]	@ resgatando o comando recebido

	nanoSleep awaitResponseUart @ aguardando atualizacao

	@b getValue

getValue:
	ldr r1, [r11, #0x0014] @ carregando do endereco  do uart_lsr
	mov r0, #1
	and r0, r1, r0		@ checando se o primeiro valor é 1 (Data Ready)

	cmp r0, #0		@ checando se o primeiro valor é 0 (Data Not Ready)

	beq getValue @ loop enquanto o valor nao foi lido

	ldr r7, [r11]	@ resgatando o valor recebido

	nanoSleep awaitResponseUart @ aguardando atualizacao

	@b checkCommand

@ endereco r5, comando r6, valor r7
checkCommand:
	cmp r6, #0x09 @ temperatura

	beq updateTemp

	cmp r6, #0x08 @ umidade

	beq updateHum 

	cmp r6, #0x1F @ sensor com problema

	beq errorSensor

	cmp r6, #0x07 @ sensor ok

	beq okSensor

	cmp r6, #0x0F @ confirmacao humidade continua

	beq activateHumConst

	cmp r6, #0x0C @ confirmacao temperatura continua

	beq activateTempConst

	cmp r6, #0x1A @ confirmacao humidade continua

	beq desactivateTempConst

	cmp r6, #0x0B @ confirmacao temperatura continua

	beq desactivateHumConst

	bx lr


updateTemp:
	mov r3, #4		
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =live_temp
	add r3, r2, r1 @ obtendo o indice correto no vetor que indica a ativacao de temp const

	ldr r0, [r3]	@ valor indicando se temp continua esta ativada

	cmp r0, #1	@ verificando se temp continua esta ativada

	beq updateTempConst @ indo para a atualizacao constante 

	ldr r1, =now_value
	str r7, [r1] @ salvando a temperatura nao constante
	
	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr

updateTempConst:
	mov r3, #4		
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =last_temp
	add r3, r2, r1 @ obtendo o indice correto do vetor de temperatura constante

	str r7, [r3] @	salvando a temperatura constante
	
	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr

updateHum:
	mov r3, #4		
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =live_hum
	add r3, r2, r1 @ obtendo o indice correto no vetor que indica a ativacao de hum const

	ldr r0, [r3]	@ valor indicando se hum continua esta ativada

	cmp r0, #1	@ verificando se hum continua esta ativada

	beq updateHumConst @ indo para a atualizacao constante 

	ldr r1, =now_value
	str r7, [r1] @ salvando a temperatura nao constante
	
	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr

updateHumConst:
	mov r3, #4		
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =last_hum
	add r3, r2, r1 @ obtendo o indice correto do vetor de humidade constante

	str r7, [r3] @	salvando a temperatura constante

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr

errorSensor:
	mov r3, #4
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =last_temp
	add r3, r2, r1 @ obtendo o indice correto do vetor de temperatura constante

	mov r0, #0x00 		@ valor que indica o nulo nos vetores de temp e hum
	str r0, [r3]		@ anulando o valor no vetor de temp const

	ldr r1, =live_temp
	add r3, r2, r1 @  obtendo o indice correto no vetor que indica a ativacao de temp const

	mov r0, #0x00		@ valor que indica o nulo nos vetores de temp e hum
	str r0, [r3]		@ anulando o valor no vetor de live_temp

	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr

okSensor:
	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido


	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr

activateHumConst:
	mov r3, #4
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =live_hum
	add r3, r2, r1 @  obtendo o indice correto no vetor que indica a ativacao de hum const

	mov r0, #1 	
	str r0, [r3]		@ ativando a humidade constante do sensor

	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr 

activateTempConst:

	mov r3, #4
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =live_temp
	add r3, r2, r1 @ obtendo o indice correto no vetor que indica a ativacao de temp const

	mov r0, #1 	
	str r0, [r3]		@ ativando a temperatura constante do sensor

	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr 

desactivateHumConst:
	mov r3, #4
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =live_hum
	add r3, r2, r1 @  obtendo o indice correto no vetor que indica a ativacao de hum const

	mov r0, #0 	
	str r0, [r3]		@ desativando a humidade constante do sensor

	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido

	ldr r1, =last_hum
	add r3, r2, r1 @ obtendo o indice correto no vetor que indica a ativacao de temp const
	str r0, [r3]		@ desativando a temperatura constante do sensor

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr 

desactivateTempConst:

	mov r3, #4
	mul r2, r5, r3		@ multiplicando o endereco dado por 4, para obter o offset

	ldr r1, =live_temp
	add r3, r2, r1 @ obtendo o indice correto no vetor que indica a ativacao de temp const

	mov r0, #0	
	str r0, [r3]		@ desativando a temperatura constante do sensor

	ldr r1, =now_command
	str r6, [r1] @ salvando o comando recebido

	ldr r1, =now_address
	str r5, [r1] @ salvando o endereco recebido

	ldr r1, =last_temp
	add r3, r2, r1 @ obtendo o indice correto no vetor que indica a ativacao de temp const
	str r0, [r3]		@ desativando a temperatura constante do sensor

	pop {r0, r1, r2, r3, r5, r6, r7}
	bx lr 