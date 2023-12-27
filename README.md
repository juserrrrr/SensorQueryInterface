# SensorQueryInterface

## Introdução

## Metodologia
Para a construção de todo o projeto solicitado, foram necessárias algumas ferramentas, assim como a leitura e análise dos datasheets de algumas delas. Como conseguinte, para a construção do projeto, foram estabelecidas a divisão em partes, a fim de modularizar e, assim, facilitar a manutenção do código, a legibilidade e também a escalabilidade, onde a base do projeto possui instruções básicas para qualquer nova adição futura.

As ferramentas utilizadas no desenvolvimento do projeto foram:
  - ORANGE PI PC PLUS
  - Display LCD HD44780
  - FPGA CYCLONE IV
  - Sensor(es) DHT11
  - Editor de Texto para escrita do código em Assembly e Terminal Linux para conexão SSH com a Orange Pi, compilação e execução do código.
  - Lucidchart, para construção de fluxogramas.


Após o conhecimento e análise das ferramentas, o projeto foi divididao nas seguintes etapas, em ordem cronológica:


  1. Chamadas de Sistema (SysCall)
      1. Pesquisa das chamadas de sistemas do sistema operacional Raspbian.
      2. Utilização das mesmas como forma de auxílio na construção do projeto.

  2. Abertura e Mapeamento da Memória
      1. Abertura da "dev/mem" por meio da chamada de sistema para obter acesso à memória física da placa.
      2. Construção de um código em Assembly para mapear a "dev/mem" em endereços lógicos por meio de outra chamada de sistema.
      3. Desenvolvimento de um código em Assembly capaz de acessar esses endereços e realizar alterações pontuais, assim como a obtenção de alguns valores.

  3. Configuração do GPIO (General Purpose Input/Output)
      1. Obtenção do endereço base referente ao GPIO.
      2. Utilização do código de mapeamento para mapear o GPIO e ter acesso aos pinos físicos da placa.
      3. Obtenção dos desvios padrões dos pinos na memória.
      4. Alocação de direções padrões para os pinos essenciais na construção do projeto.

  4. Configuração da UART na Orange Pi
      1. Obtenção do endereço base referente ao CCU (Clock Control Unit) e também à UART.
      2. Utilização do código de mapeamento para mapear a CCU e, em seguida, a UART.
      3. Obtenção dos desvios padrões referentes à configuração da CCU e UART.
      4. Configuração da CCU para liberação do clock para UART.
      5. Configuração da UART para definição da baudrate e também do FIFO.

  5. Utilizando o Display LCD
      1. Utilização dos pinos já configurados e mapeados para enviar sinais para o display.
      2. Necessário inicializar o display antes de qualquer operação.
      3. Configuração para o modo de 4 bits a fim de sincronizar com a disposição de pinos na placa.
      4. Criação de algumas macros/funções para funcionalidades básicas do controlador.
## Descrição do Projeto:

### MAPEAMENTO
O mapeamento constitui um dos pontos-chave do projeto, uma vez que é aplicado em todas as outras funcionalidades necessárias e adicionais. Com esse propósito em mente, para iniciar a compreensão da construção desta parte do projeto, tornou-se imperativo consultar um manual sobre como começar no Raspbian, utilizando o [raspberry pi assembly language](public/raspberry-pi-assembly-language-programming-arm-processor-coding-9781484252864-9781484252871-1484252861_compress.pdf), a fim de compreender conceitos básicos, como as chamadas de sistema para atingir o objetivo proposto. Aqui entra outro detalhe: como o sistema operacional estava instalado em uma Orange Pi, cujo hardware e funcionamento diferem um pouco do Raspberry Pi, foi necessário também consultar o [Datasheet da OrangePi Pc Plus](public/Allwinner_H3_Datasheet_V1.2.pdf) para obter informações mais detalhadas sobre os endereços base e desvios na memória.

Com base nesse conhecimento adquirido, tornou-se evidente a necessidade de desenvolver um arquivo em assembly com o único objetivo de lidar com essa parte específica do projeto. Essa abordagem, naturalmente, busca a modularização, permitindo atender a todas as necessidades sem a constante criação de novos códigos ou alterações nos já existentes. A partir dessa concepção e da leitura dos arquivos mencionados anteriormente, foi essencial a construção de funções e macros. Essas estruturas foram criadas para modificar a direção dos pinos físicos, obter o valor que o pino está recebendo e enviar um valor através do pino, seja em nível lógico alto ou baixo, garantindo assim uma abordagem abrangente e flexível. Tudo isso para o mapeamento do GPIO.

Essas alterações no direcionamento serão empregadas para configurar os pinos no modo UART TX e RX, assim como no modo de entrada (input) para capturar informações quando um botão for pressionado. Além disso, será necessário direcionar os pinos como saída para enviar sinais para o LCD. Mais adiante, será abordado detalhadamente o uso de outros mapeamentos, como o da CCU e também da UART, com o propósito de liberar o clock para UART e configurá-la, utilizando um endereço base e seus desvios correspondentes.


## Resultados e análise dos testes

## Conclusão

## Referências

## Autores

- José Gabriel de Almeida Pontes
- Luis Guilherme Nunes Lima
- Pedro Mendes
- Thiago Pinto Pereira Sena
