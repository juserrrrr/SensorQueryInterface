# SensorQueryInterface

## Introdução

## Metodologia
      
### UART

A comunicação entre a FPGA e a Orange Pi se dá por meio do envio e recebimento de comandos e respostas, essa transmissão é feita através do protocolo UART (Universal Asynchronous Receiver Transmitter. O detalhamento do protocolo implementado, bem como o significado dos códigos utilizados podem ser vistos em [Sensor Query ReadMe](https://github.com/juserrrrr/DigitalSensorQuery/blob/main/README.md).

A configuração da UART na Orange Pi é feita a partir do acesso de endereços de memória, endereços esses que estão descritos no datasheet citado previamente. Existem dois endereços base que foram utilizados para configurar a UART, o primeiro é o da CCU (Clock Control Unit), que fica responsável por gerar e controlar o clock que é utilizado na UART, e o segundo é o da própria UART, onde são setadas as preferências de transmissão de dados.

Na CCU, os seguintes endereços foram modificados:

Nome do Offset | Nome da Função | Descrição|
| --- | --- | --- |
|  Bus Clock Gating Reg3 |  UART3_GATING | Libera o clock para a UART 3  |
|  PLL_PERIPH0 Control   |  PLL_ENABLE | Gera o clock de 600mhz |
|  APB2 Configuration   |  APB2_CLK_SRC_SEL | Seleciona o PLL_PERIPH0 como fonte do clock da UART |
|  Bus Software Reset Reg4  |  UART3_RST | Liga ou desliga a UART |


Após configurar a geração de clock da UART, bem como resetá-la para garantir o pleno funcionamento, a configuração segue para o endereço base da própria UART:

Nome do Offset | Nome da Função | Descrição|
| --- | --- | --- |
|  UART FIFO Control |  FIFOE | Ativa o modo FIFO |
|  UART FIFO Control  |  RFIFOR | Reseta o receiver da FIFO |
|  UART FIFO Control |  XFIFOR | Reseta o transmitter da FIFO |
|  UART Line Control  |  DLAB | Permite a configuração de Baud Rate (desliga a UART se ativado) |
|  UART Divisor Latch Low |  DLL | Menores 8 bits do resultado da fórmula que determina a Baud Rate|
|  UART Divisor Latch High |  DLH | Maiores 8 bits do resultado da fórmula que determina a Baud Rate|
|  UART Line Control |  DLS | Seta o modo de operação para 8 bits por vez|
|  UART Reciever Buffer |  RBR | Buffer que recebe os valores da UART|
|  UART Transmit Holding |  THR | Registrador que envia os valores pela UART|
|  UART Line Status |  DR | Indica se existe algum dado para ser lido no RBR|

Após a configuração , o DLAB é setado em 0 novamente, para permitir o uso da UART.

O envio de dados no código é bem simples, o valor é carregado para o THR e enviado automaticamente. Já o recebimento requer um tratamento mais complexo.

Existem quatro vetores de words no .data responsáveis por controlar e guardar os valores contínuos que são recebidos pela UART, além de três words que guardam a última resposta recebida. Já que o comando de resposta de um valor contínuo é o mesmo de um não contínuo, um dos vetores fica responsável por guardar a informação de que um determinado sensor foi setado como contínuo anteriormente, seja para umidade ou temperatura, para que a informação seja impressa na tela de contínuos, e não na de valor atual.

A leitura do RBR é feita constantemente, sempre que o DR (Data Ready) está em 1, indicando que existe algum dado para ser lido, dado esse que sempre será primeiramente um endereço, depois um comando e logo em seguida um valor recebido.


## Descrição do Projeto:

## Resultados e conclusão

O projeto cumpriu todas as funções requisitadas, e consegue mostrar as temperaturas e umidades contínuas de diversos sensores, ao mesmo tempo que recebe novas requisições para os demais. Vários desafios foram encontrados e resolvidos durante o desenvolvimento e testes do projeto, em especial os que envolviam a interpretação dos datasheets. A inicialização do display LCD e da UART necessitou ampla leitura e diversos testes, já que vários detalhes são necessários para que ambos funcionem corretamente.

A utilização de funções para melhor execução do código também trouxe desafios, já que o uso de registradores sem o devido tratamento para que as informações previamente guardadas neles fossem perdidas trouxe diversos problemas, que foram solucionados com o uso correto das instruções de "push" e "pop".

Um ponto de melhoria que fica evidente é a possibilidade de informar os comandos para o usuário de forma mais intuitiva, como usar a sigla "TC" para indicar que será enviado um comando de "Ativar Temperatura Constante".

Algumas telas do projeto em funcionamento:

<img src="https://github.com/juserrrrr/SensorQueryInterface/blob/mendes/public/continuo.jpg" width="350">

<img src="https://github.com/juserrrrr/SensorQueryInterface/blob/mendes/public/sensorok.jpg" width="350">

<img src="https://github.com/juserrrrr/SensorQueryInterface/blob/mendes/public/envio.jpg" width="350">

## Referências

## Autores

- José Gabriel de Almeida Pontes
- Luis Guilherme Nunes Lima
- Pedro Mendes
- Thiago Pinto Pereira Sena
