.include "fileio.s"
.include "unistd.s"
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



.macro mapMem
    openFile devmem, S_RDWR @ open /dev/mem
    movs r4, r0 @ fd for memmap
    @ check for error and print error msg if necessary
    BPL 1f @ pos number file opened ok
    MOV R1, #1 @ stdout
    LDR R2, =memOpnsz @ mensagem de err
    LDR R2, [R2]
    writeFile R1, memOpnErr, R2 @ print the error
    B _end
    
@ Configuração para chamar o serviço Linux mmap2
1:  ldr r5, =gpioaddr @ endereço que queremos / 4096
    ldr r5, [r5] @ carrega o endereço
    mov r1, #pagelen @ tamanho da memória que queremos
@ mem protection options
    mov r2, #(PROT_READ + PROT_WRITE)
    mov r3, #MAP_SHARED @ opções de compartilhamento de memória
    mov r0, #0 @ deixar o linux escolher um endereço virtual
    mov r7, #sys_mmap2 @ Número de serviço mmap2
    svc 0 @ Serviço de chamada
    movs r8, r0 @ Mantenha o virtual address retornado
    add r8, #0x800 @ pra chegar na pagina
    @ checagem de erro e printa mensagem de erro se necessário
    MVN r0, #0 @ inverte o sinal
    CMP r8, r0 @ compara o endereço retornado com -1
    BNE success @ se não for -1, então deu certo
    MOV R1, #1 @ stdout
    LDR R2, =memMapsz @ mensagem de erro
    LDR R2, [R2]
    writeFile R1, memMapErr, R2 @ printa o erro
    B _end

success:
.endm


.macro GPIOSetDirection direction, pin @Dá pra colocar para passar o tipo de pino como argumento
    ldr r4, =\pin @ endereço de registros gpio
    ldr r2, [r4] @ carrega o endereço do vetor dos pinos
    ldr r1, [r8, r2] @ carrega o estado atual do vetor dos pinos
    ldr r3, [r4, #4] @ carrega o endereço do vetor das funções

    mov r0, #0b111 @ mascara para limpar os bits
    lsl r0, r3 @ desloca a mascara para a posição
    bic r1, r0 @ limpa os bits

    mov r4, #\direction @ seta o valor da direção
    lsl r4, r3 @ desloca o valor para a posição
    orr r1, r4 @ seta o bit da direção
    str r1, [r8, r2] @ escreve no registrador
.endm


.macro GPIOSet pin, value
    ldr r3, =\pin @ base da tabela de informações do pino
    ldr r2, [r3, #8] @ carrega o desvio do vetor dos pinos
    ldr r1, [r8, r2] @ Carrega o estado atual do vetor dos pinos
    ldr r3, [r3, #12] @ carrega a posição requerida do pino no vetor

    mov r0, #1 @ seta um bit 1, para fazer a mascara
    lsl r0, r3 @ desloca até a posição do pino no vetor
    bic r1, r0 @ Limpa o bit do pino no vetor

    mov r0, #\value @ seta o valor que vai ser escrito no pino
    lsl r0, r3 @ desloca o valor para a posição do pino
    orr r1, r0 @ seta o bit do pino no vetor

    str r1, [r8, r2] @ Salva o vetor modificado na memoria

.endm


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
    @=================Tabela de informações dos pinos========================|
    @LED AZUL(INVERTIDO) - PINO 33
    pin_PA09:   .word 0x04 @ Desvio para selecionar o registro DO PA
                .word 4 @ Posição do vetor para configurar sua função.
                .word 0x10 @ Desvio para selecionar a data de setagem do valor do pino.
                .word 9 @ Posição do vetor para configurar o valor do pino.


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
    @D4 LCD - PINO 32 - pin_PG08
    pin_D4:     .word 0xDC @ Desvio para selecionar o registro DO PA
                .word 0 @ Posição do vetor para configurar sua função.
                .word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
                .word 8 @ Posição do vetor para configurar o valor do pino.

    @D5 LCD - PINO 36 - pin_PG09
    pin_D5:     .word 0xDC @ Desvio para selecionar o registro DO PA
                .word 4 @ Posição do vetor para configurar sua função.
                .word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
                .word 9 @ Posição do vetor para configurar o valor do pino.

    @D6 LCD - PINO 38 - pin_PG06
    pin_D6:     .word 0xD8 @ Desvio para selecionar o registro DO PA
                .word 24 @ Posição do vetor para configurar sua função.
                .word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
                .word 6 @ Posição do vetor para configurar o valor do pino.
                            
    @D7 LCD - PINO 40 - pin_PG07			
    pin_D7:     .word 0xD8 @ Desvio para selecionar o registro DO PA
                .word 28 @ Posição do vetor para configurar sua função.
                .word 0xE8 @ Desvio para selecionar a data de setagem do valor do pino.
                .word 7 @ Posição do vetor para configurar o valor do pino.


    liveTemp:		.word -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
				    .word -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1

    liveHum:		.word -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    .word -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    
    lastInfo:		.word -1, -1	
    
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

