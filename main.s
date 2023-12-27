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
    @ mov r6, #15.include "unistd.s"
.include "fileio.s"
.include "memManagement.s"
.include "utils.s"
.include "uart.s"
.include "codesLCD.s"
.include "control.s"
.include "windowsLcd.s"

@ R10: Registrador para salvar o endereço do mapeamento do GPIO
@ R11: Registrador para salvar o endereço do mapeamento do UART
@ R12: Registrador para salvar o endereço do mapeamento do CCU

.section .text
.global _start
_start:	
	@Fica salvo o REG4 nessa macro então é preciso que os mapeamentos estejam necessariamente em seguida.
	openDevMem @Abertura do arquivo de memoria

	mappingConfig: @Configuração do mapeamento da memoria
		ldr r5, =gpioaddr
		mov r6, #0x800
		bl mappingMemory
    	mov r10, r0

		ldr r5, =uartaddr
		mov r6, #0xC00
		bl mappingMemory
		mov r11, r0

		ldr r5, =ccuaddr
		mov r6, #0
		bl mappingMemory
		mov r12, r0
	@ Liberado usar o REG4 novamente.
	setPinsDirection: @Configuração de direcionamento dos pinos		
		setLcdPins
		setUartPins
		setBtnsPins

	configureMemory: @Configuração dos registradores da memoria
		configCcu
		configUart

	startupLcd: @Inicialização do LCD
		initialize
		nanoSleep oneSecond

		ldr r5, =tela_boas_vindas 
		bl writeString @Escreve a tela de boas vindas
		nanoSleep twoSeconds @Deixa a tela por 2 segundos
		clearDisplay @Limpa o display

	choiceCommadSensor: @ Tela para escolha do sensor e do comando

		bl telas @Escolha sensor x comando
		
		ldr r5, =sensorEscolhido
		ldr r5, [r5]
		str r5, [r11] @ enviando valor pela uart	

		ldr r5, =comandoEscolhido
		ldr r5, [r5]
		str r5, [r11] @ enviando valor pela uart	

		ldr r5, =tela_aguardando 
		bl writeString

	loopResponseLCD: @Loop que fica esperando a resposta do LCD pela UART
		bl setGatingOn

		bl getUart 

		ldr r1, =now_command
		ldr r1, [r1]
		
		
		@Se comando for de medida de temp atual
		ldr r5, =tela_temperatura_atual 
		cmp r1, #0x09 @Medida de temp
		beq currentValue
		
		@Se comando for de umidade de temp atual
		ldr r5, =tela_umidade_atual
		cmp r1, #0x08 @Medida de Umidade
		beq currentValue
		
		@Se comando for de status do sensor OK
		ldr r5, =tela_sensor_funcionando
		cmp r1, #0x07 @Sensor OK
		beq statusSensor
		
		@Se comando for de status do sensor Não OK
		ldr r5, =tela_sensor_nao_funcionando
		cmp r1, #0x1f @Sensor não OK
		beq statusSensor
		
		@Se comando for de ativacao da temp
		ldr r5, =tela_ativacao_temp_sensor
		cmp r1, #0x0c @Confirmação de ativação de temperatura
		beq activate
		
		@Se comando for de ativacao da umid
		ldr r5, =tela_ativacao_umid_sensor
		cmp r1, #0x0f @Confirmação de ativação de umidade
		beq activate
		
		@Se comando for de desativacao da temp
		ldr r5, =tela_desativacao_temp_sensor
		cmp r1, #0x1a @Confirmação de desativação de temperatura
		beq activate
		
		@Se comando for de desativacao da umid
		ldr r5, =tela_desativacao_umid_sensor
		cmp r1, #0x0b @Confirmação de desativação de umidade
		beq activate

	botaoImediato:
		ldr r1, =pin_BTN1
		GPIOGet r1
		cmp r0, #0 @Se botão de incremento pressionado
		beq next
		
		ldr r1, =pin_BTN0
		GPIOGet r1
		cmp r0, #0 @Se botão de decremento pressionado
		beq previous
		
		ldr r1, =pin_BTN2
		GPIOGet r1
		cmp r0, #0 @Se botão de enter pressionado
		beq sensorComand

		ldr r1, =now_command
		mov r2, #0xFF
		str r2, [r1]
		b loopResponseLCD
	
	@Funções de auxilio para recebimento dos dados
	currentValue:
		bl showSensorValue
		b botaoImediato

	statusSensor:@Imprimir telas de status do sensor
		bl showSensorStatus
		b botaoImediato
		
	activate:@Imprimir telas de ativação de umidade ou temperatura
		bl showActivate
		b botaoImediato
		
	next: @Vai para proxima tela a partir da atual
		ldr r1, =pin_BTN1 
		bl debouncerLoop @DEBOUNCER PARA O BOTÃO
		mov r7, #0
		b contiune

@Funções dos botões
	previous: @Volta para uma tela a partir da atual
		ldr r1, =pin_BTN0
		bl debouncerLoop @DEBOUNCER PARA O BOTÃO
		mov r7, #6
		b contiune

	sensorComand: @Vai para a tela de escolha do sensor e do comando
		ldr r1, =pin_BTN2
		bl debouncerLoop @DEBOUNCER PARA O BOTÃO
		b choiceCommadSensor
		

	@Tela dos contínuos
	contiune: @Vai para a tela dos contínuos
		ldr r5, =tela_dois_continuos
		bl writeString
		mov r7, #0
		
	@Loop que mantém na tela dos contínuos e atualiza os valores até apertar o botão
	startLiveValueLoop:
		bl setGatingOn
		bl getUart
		bl showTwoConstant @Mostra a tela dos contínuos

		ldr r1, =pin_BTN1
		GPIOGet r1
		cmp r0, #0 @Se botão de incremento pressionado
		beq nextLive
		
		ldr r1, =pin_BTN0
		GPIOGet r1
		cmp r0, #0 @Se botão de decremento pressionado
		beq previousLive
		
		ldr r1, =pin_BTN2
		GPIOGet r1
		cmp r0, #0 @Se botão de enter pressionado
		beq sensorComand

		b startLiveValueLoop

	@Funções dos botões

	nextLive: @Vai para a proxima tela continua
		ldr r1, =pin_BTN1
		bl debouncerLoop

		add r7, #2 @incrementa 2
		cmp r7, #8
		beq endTelas @Se mostrei os contínuos do sensor 0 ao 7, volto pro comando
		b startLiveValueLoop @senão, vou para o próximo contínuo

	previousLive: @Volta para a tela anterior dos contínuos
		ldr r1, =pin_BTN0
		bl debouncerLoop

		cmp r7, #0
		beq endTelas @Se mostrei os contínuos do sensor 0 ao 7, volto pro comando
		sub r7, #2 @incrementa 2
		b startLiveValueLoop @senão, vou para o próximo contínuo
		
	endTelas: @Ao final dos contínuos, volta para a tela de escolha do sensor e do comando
		b choiceCommadSensor

_end: @Finalização do programa.
    mov R0, #0 @ Use 0 return code
    mov R7, #1 @ Command code 1 terms
    svc 0 @ Linux command to terminate

.data

	@===============Mensagens de erro=================|
	devmem:     .asciz "/dev/mem"   @ caminho do arquivo de memoria
	memOpnErr:  .asciz "Failed to open /dev/mem\n" @ mensagem de erro
	memOpnsz:   .word .-memOpnErr @ tamanho da mensagem de erro
	memMapErr:  .asciz "Failed to map memory\n" @ mensagem de erro
	memMapsz:   .word .-memMapErr @ tamanho da mensagem de erro
							.align 4 @ realinhar depois das strings de 4 byts
	@================Endereço base do mapeamento da memoria=================|
	gpioaddr:   .word 0x1C20 @ 0x01C20800 / 0x1000 (4096) = 0x01C20 Endereço de memória do GPIO / 4096(Tamanho da pagina)
	uartaddr:	.word 0x1C28 @ Resto 0xC00
	ccuaddr: 	.word 0x1C20 @ Sem resto
	
	@================Offsets ccu============================================|
	bus_clk:	.word 0x006C @ uart3 gating, bit 19: 1
	pll_ph0:	.word 0x0028 @ enable, bit 31: 1
	abp2:	.word 0x0058 @ clk_src, bit 24: 10 (pll), 01 (osc24m)
	bus_soft:	.word 0x02D8 @ uart3_rst, bit 19: 1
	
	@================Offsets Uart===========================================|
	uart_rbr:	.word 0x00	@ reciever buffer
	uart_thr:	.word 0x00	@ transmit holding
	uart_dll:	.word 0x00	@ divisor latch low (11110100001001 = 15625) 00001001 no low 111101 no high
	uart_dlh:	.word 0x04	@ divisor latch high
	uart_lcr:	.word 0x0C	@ line control, dlab bit 7: 1 para config. uart
					@ dls bit 0: 11 para 8 bits
	uart_lsr:	.word 0x14	@ line status
					@ thre bit 5: 1 indica que o TX está livre
					@ data ready bit 0: 1 indica que há um dado para ser lido
	uart_fcr:	.word 0x08  @ fcr, fifo enable bit 0: 1

	sensorEscolhido: .word 0xFF

	comandoEscolhido: .word 0xFF
		
	@=================Tabela de informações dos pinos========================|
	@PIN PA7(INVERTIDO) - 
	pin_BTN0:   .word 0x00 @ Desvio para selecionar o registro DO PA
							.word 28 @ Posição do vetor para configurar sua função.
							.word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 7 @ Posição do vetor para configurar o valor do pino.
	
	@PIN PA10(INVERTIDO) - 
	pin_BTN1:   .word 0x04 @ Desvio para selecionar o registro DO PA
							.word 8 @ Posição do vetor para configurar sua função.
							.word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 10 @ Posição do vetor para configurar o valor do pino.
	
	@PIN PA20(INVERTIDO) - 
	pin_BTN2:   .word 0x08 @ Desvio para selecionar o registro DO PA
							.word 16 @ Posição do vetor para configurar sua função.
							.word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 20 @ Posição do vetor para configurar o valor do pino.
	
	@LED AZUL(INVERTIDO) - PINO 33
	pin_PA09:   .word 0x04 @ Desvio para selecionar o registro DO PA
							.word 4 @ Posição do vetor para configurar sua função.
							.word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 9 @ Posição do vetor para configurar o valor do pino.
	
	@LED AZUL(INVERTIDO) - PINO 33
	pin_PA08:   .word 0x04 @ Desvio para selecionar o registro DO PA
							.word 0 @ Posição do vetor para configurar sua função.
							.word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 8 @ Posição do vetor para configurar o valor do pino.

	@E LCD - PINO 28 - pin_PA18
	pin_E:      .word 0x08 @ Desvio para selecionar o registro DO PA
							.word 8 @ Posição do vetor para configurar sua função.
							.word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 18 @ Posição do vetor para configurar o valor do pino.

	@RS LCD - PINO 22 - pin_PA02
	pin_RS:     .word 0x00 @ Desvio para selecionar o registro DO PA
							.word 8 @ Posição do vetor para configurar sua função.
							.word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 2 @ Posição do vetor para configurar o valor do pino.
	
	@D7 LCD - PINO 40 - pin_PG07			
	pin_D7:     .word 0xD8 @ Desvio para selecionar o registro DO PA
							.word 28 @ Posição do vetor para configurar sua função.
							.word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 7 @ Posição do vetor para configurar o valor do pino.
	@D6 LCD - PINO 38 - pin_PG06
	pin_D6:     .word 0xD8 @ Desvio para selecionar o registro DO PA
							.word 24 @ Posição do vetor para configurar sua função.
							.word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 6 @ Posição do vetor para configurar o valor do pino.
	@D5 LCD - PINO 36 - pin_PG09
	pin_D5:     .word 0xDC @ Desvio para selecionar o registro DO PA
							.word 4 @ Posição do vetor para configurar sua função.
							.word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 9 @ Posição do vetor para configurar o valor do pino.
	@D4 LCD - PINO 32 - pin_PG08
	pin_D4:     .word 0xDC @ Desvio para selecionar o registro DO PA
							.word 0 @ Posição do vetor para configurar sua função.
							.word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
							.word 8 @ Posição do vetor para configurar o valor do pino.


													
	
	
	@UART TX - PINO 8 - pin_PA13
	uart_tx:	.word 0x04
				.word 20
				
	@UART RX - PINO 10 - pin_PA14
	uart_rx:	.word 0x04
				.word 24
	
	live_temp:	.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
							.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
							.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
							.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				
	live_hum:  .word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

	last_temp:  .word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				
	last_hum:  .word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				.word 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
				
	now_address:    .word 0xFF
	
	now_command:    .word 0xFF
	
	now_value:	    .word 0xFF


	@=================Valores dos estados do botão============================|

	lastBtnValue:  .word 0b111

	@ ==================Temporização para o nanoSleep=========================|
	remainingEnableTime:    .word 0         @Segundos
													.word 600       @Nano Segundos

	totalLoadingTimeRs:     .word 0         @Segundos
													.word 60        @Nano Segundos

	totalEnableTimeHigh:    .word 0         @Segundos
													.word 450       @Nano Segundos

	awaitInstruction:       .word 0         @Segundos
													.word 40000     @Nano Segundos

	awaitInstructionHome:   .word 0         @Segundos
													.word 2000000    @Nano Segundos

	awaitResponseUart: 			.word 0
													.word 30000000
	
	fiveMilliSeconds:   		.word 0         @Segundos
													.word 100000000    @Nano Segundos

	oneSecond:              .word 1         @Segundos
													.word 0         @Nano Segundos

	twoSeconds:             .word 2         @Segundos
													.word 0         @Nano Segundos
	
	timerLcd1:  .word 0
							.word 16000000

	timerLcd2:	.word 0
							.word 5500000

	timerLcd3:	.word 0 
							.word 150000


	@ ==================Padrões de telas do LCD=========================|

	tela_boas_vindas:
	.ascii "Bem-vindo(a)  ao\n"
	.asciz "  Sensor Query  "
	
	tela_teste:
			.ascii "Sensor: 0\n"
	.asciz "Comando: 0x00"
		
	tela_temperatura_atual:
	    .ascii "Temperatura do\n"
		.asciz "Sensor 0: 00*C"
		
	tela_umidade_atual:
	    .ascii "Umidade do\n"
		.asciz "Sensor 0: 00%"
		
	tela_sensor_funcionando:
	    .ascii "Sensor 0 OK!\n"
		.asciz "      (^_^)     "
	
	tela_sensor_nao_funcionando:
	    .ascii "Sensor 0 NAO OK!\n"
		.asciz "      (T_T)     "
		
	tela_dois_continuos:
		.ascii "00: T=00*C H=00%\n"
		.asciz "00: T=00*C H=00%"
	
	tela_ativacao_temp_sensor:
	    .ascii "Temperatura do\n" 
	    .asciz "Sensor 0 ativada"
	    
	tela_ativacao_umid_sensor:
	    .ascii "Umidade do\n" 
	    .asciz "Sensor 0 ativada"
	    
	tela_desativacao_temp_sensor:
	    .ascii "Temperatura do\n" 
	    .asciz "Sensor 0 desativ"
	    
	tela_desativacao_umid_sensor:
	    .ascii "Umidade do\n" 
	    .asciz "Sensor 0 desativ"

	tela_aguardando:
		.ascii "Aguardando ...\n"
		.asciz ""
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
    ldr r9, =uart3_base         @ carregando o reg base da uart3
    add r9, r9, #uart_lsr        @ indo para o offset do lsr
    ldr r9, [r9]                @ carregando o reg do lsr
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
    ldr r9, =uart3_base         @ carregando o reg base da uart3
    add r9, r9, #uart_lsr        @ indo para o offset do lsr
    ldr r9, [r9]                @ carregando o reg do lsr
    lsr r9, #lsr_dr           @ jogando o bit de verificação para a primeira posição
    mov r10, #1                 @ máscara para pegar o primeiro bit

    and r10, r9, r10           
    cmp r10, #0

    beq end_readUart            @ caso não tenha caractere para ser lido, fim da função

    ldr r12, [r9, #uart_thr]    @ salva o valor que veio pela uart no r12 (endereço)

    ldr r8, =currentInfo    @ endereço da currentInfo
    str r12, [r8]     @ guarda o valor do endereço na currentInfo

    mov r11, #1                  @ contador para ler os outros 2 bytes

readRemaining:
    cmp r11, #3
    beq end_readUart                    @ se o contador = 3, todos os bytes foram lidos

    ldr r9, =uart3_base         @ carregando o reg base da uart3
    add r9, r9, #uart_lsr        @ indo para o offset do lsr
    ldr r9, [r9]                @ carregando o reg do lsr
    lsr r9, #lsr_dr                         @ jogando o bit de verificação para a primeira posição
    mov r10, #1                             @ máscara para pegar o primeiro bit

    and r10, r9, r10           
    cmp r10, #0
    beq readRemaining                       @ caso não tenha caractere para ser lido, loop até chegar

    add r11, r11, #1                @ somando 1 ao contador

    ldr r12, [r9, #uart_thr]    @ salva o valor que veio pela uart no r12 (endereço)

    add r8, r8, #4                  @ indo para o proximo índice na currentInfo
    str r12, [r8]     @ guarda o valor do endereço na currentInfo

end_readUart:
    bx lr


