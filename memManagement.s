@
@ Arquivo responsável pelo gerenciamento da memoria do projeto
@ 


@|===== Configurações =====|
.equ pagelen, 0x1000      @ tamanho da pagina de memoria  
.equ PROT_READ, 1       @ permissão de leitura
.equ PROT_WRITE, 2      @ permissão de escrita
.equ MAP_SHARED, 1      @ compartilhamento de memoria
@|===== Níveis lógicos =====|
.equ high, 0b1     @ nivel logico alto
.equ low, 0b0      @ nivel logico baixo
@|===== Direção dos pinos =====|
.equ input, 0b000     @ direção para pino de entrada
.equ output, 0b001    @ direção para pino de saida
.equ uart3, 0b011    @ direção para uart3


.macro openDevMem
		openFile devmem, S_RDWR @ open /dev/mem
		movs r4, r0 @ fd for memmap
		@ check for error and print error msg if necessary
		bpl successOpenFile @ pos number file opened ok
		mov R1, #1 @ stdout
		ldr R2, =memOpnsz @ mensagem de err
		ldr R2, [R2]
		writeFile R1, memOpnErr, R2 @ print the error
		b _end
	successOpenFile:
.endm


.macro GPIOSet pin, value
   push {r1-r3}

   mov r3, \pin @ base da tabela de informações do pino
   ldr r2, [r3, #8] @ carrega o desvio do vetor dos pinos
   ldr r1, [r10, r2] @ Carrega o estado atual do vetor dos pinos
   ldr r3, [r3, #12] @ carrega a posição requerida do pino no vetor

    mov r0, #1 @ seta um bit 1, para fazer a mascara
    lsl r0, r3 @ desloca até a posição do pino no vetor
    bic r1, r0 @ Limpa o bit do pino no vetor

    mov r0, \value @ seta o valor que vai ser escrito no pino
    lsl r0, r3 @ desloca o valor para a posição do pino
    orr r1, r0 @ seta o bit do pino no vetor

    str r1, [r10, r2] @ Salva o vetor modificado na memoria
    pop {r1-r3}
.endm

.macro GPIOGet pin
		push {r1, r2, r3}
    mov r3, \pin @ base da tabela de informações do pino
    ldr r2, [r3, #8] @ carrega o desvio do vetor dos pinos
    ldr r1, [r10, r2] @ Carrega o estado atual do vetor dos pinos
    ldr r3, [r3, #12] @ carrega a posição requerida do pino no vetor

    mov r0, #1 @ seta um bit 1, para fazer a mascara
    lsl r0, r3 @ desloca até a posição do pino no vetor
    and r1, r0 @ Limpa o bit do pino no vetor

    lsr r1, r3 @ desloca o valor para a posição inicial
    mov r0, r1 @ salva o valor no registrador de retorno

		pop {r1, r2, r3}
.endm

setDirectionGPIO: @ EX GPIOSetDirection
	push {r0-r3}

	ldr r2, [r4] @ carrega o endereço do vetor dos pinos
	ldr r1, [r10, r2] @ carrega o estado atual do vetor dos pinos
	ldr r3, [r4, #4] @ carrega o endereço do vetor das funções

	mov r0, #0b111 @ mascara para limpar os bits
	lsl r0, r3 @ desloca a mascara para a posição
	bic r1, r0 @ limpa os bits

	mov r4, r5 @ seta o valor da direção
	lsl r4, r3 @ desloca o valor para a posição
	orr r1, r4 @ seta o bit da direção
	str r1, [r10, r2] @ escreve no registrador

	pop {r0-r3}
	bx lr

mappingMemory:
	push {r1-r3, r7}
	ldr r5, [r5] @ carrega o endereço
	mov r1, #pagelen @ tamanho da memória que queremos
	@ Opções de protenção de mapemaneto de memoria
	mov r2, #(PROT_READ + PROT_WRITE)
	mov r3, #MAP_SHARED @ opções de compartilhamento de memória
	mov r0, #0 @ deixar o linux escolher um endereço virtual
	mov r7, #sys_mmap2 @ Número de serviço mmap2
	svc 0 @ Serviço de chamada

	@ checagem de erro e printa mensagem de erro se necessário
	cmp r0, #0xFFFFFFFF @ compara o endereço retornado com -1
	bne successMap @ se não for -1, então deu certo
	mov R1, #1 @ stdout
	ldr R2, =memMapsz @ mensagem de erro
	ldr R2, [R2]
	writeFile R1, memMapErr, R2 @ printa o erro
	b _end
successMap:
	add r0, r6 @ Offset para ajeitar o desvio.
	pop {r1-r3, r7}
	bx lr @ retorna r0

    
@ Padrões de pinagem ----------------=|
@ PA REGISTER
@ PA PIN (0~7) OFFSET(DESVIO)  : 0x00
@ PIN0 = [2:0] PIN1 = [6:4] PIN2 = [10:8] PIN3 = [14:12] PIN4 = [18:16] PIN5 = [22:20] PIN6 = [26:24] PIN7 = [30:28]
@ PA PIN (8~15) OFFSET(DESVIO) : 0x04
@ PIN8 = [2:0] PIN9 = [6:4] PIN10 = [10:8] PIN11 = [14:12] PIN12 = [18:16] PIN13 = [22:20] PIN14 = [26:24] PIN15 = [30:28]
@ PA PIN (16~21) OFFSET(DESVIO): 0x08
@ PIN16 = [2:0] PIN17 = [6:4] PIN18 = [10:8] PIN19 = [14:12] PIN20 = [18:16] PIN21 = [22:20]

@ PC REGISTER
@ PC PIN (0~7) OFFSET(DESVIO)  : 0x48
@ PIN0 = [2:0] PIN1 = [6:4] PIN2 = [10:8] PIN3 = [14:12] PIN4 = [18:16] PIN5 = [22:20] PIN6 = [26:24] PIN7 = [30:28]
@ PC PIN (8~15) OFFSET(DESVIO) : 0x4C
@ PIN8 = [2:0] PIN9 = [6:4] PIN10 = [10:8] PIN11 = [14:12] PIN12 = [18:16] PIN13 = [22:20] PIN14 = [26:24] PIN15 = [30:28]
@ PC PIN (16) OFFSET(DESVIO)   : 0x50
@ PIN16 = [2:0]

@ PD REGISTER
@ PD PIN (0~7) OFFSET(DESVIO)  : 0x6C
@ PIN0 = [2:0] PIN1 = [6:4] PIN2 = [10:8] PIN3 = [14:12] PIN4 = [18:16] PIN5 = [22:20] PIN6 = [26:24] PIN7 = [30:28]
@ PD PIN (8~15) OFFSET(DESVIO) : 0x70
@ PIN8 = [2:0] PIN9 = [6:4] PIN10 = [10:8] PIN11 = [14:12] PIN12 = [18:16] PIN13 = [22:20] PIN14 = [26:24] PIN15 = [30:28]
@ PC PIN (16~17) OFFSET(DESVIO): 0x74
@ PIN16 = [2:0] PIN17 = [6:4]

@ PG REGISTER
@ PG PIN (0~7) OFFSET(DESVIO)  : 0xD8
@ PIN0 = [2:0] PIN1 = [6:4] PIN2 = [10:8] PIN3 = [14:12] PIN4 = [18:16] PIN5 = [22:20] PIN6 = [26:24] PIN7 = [30:28]
@ PG PIN (8~15) OFFSET(DESVIO) : 0xDC
@ PIN8 = [2:0] PIN9 = [6:4] PIN10 = [10:8] PIN11 = [14:12] PIN12 = [18:16] PIN13 = [22:20] 

@ DATA REGISTER(PADRÃO VETOR 0000000000[x:0])
@ PA DATA(ON & OFF)
@ PIN'S(0~21) OFFSET(DESVIO)  : 0x10

@ PC DATA(ON & OFF)
@ PIN'S(0~18) OFFSET(DESVIO)  : 0x58 (PINOS 17 e 18 SEM USO)

@ PD DATA(ON & OFF)
@ PIN'S(0~17) OFFSET(DESVIO)  : 0x7C

@ PG DATA(ON & OFF)
@ PIN'S(0~13) OFFSET(DESVIO)  : 0xE8
@-------------------------------------=|
