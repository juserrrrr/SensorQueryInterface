# SensorQueryInterface

## Introdução
O acompanhamento remoto de ambientes fundamenta-se primordialmente no paradigma da Internet das Coisas (IoT). A transformação introduzida pelo mercado de IoT está reconfigurando a economia global de maneira extraordinária, ao proporcionar maior eficiência, estimular inovações e impulsionar melhorias significativas em diversos setores. De acordo com Perles et al. (2018), a conservação preventiva do patrimônio cultural, como obras de arte e artefatos históricos, é aprimorada hoje através da gestão de dados coletados por sensores eletrônicos

Com o crescimento do mercado de Internet das Coisas (IoT), uma empresa que deseja ingressar nesse setor solicitou aos estudantes de Engenharia da Computação da UEFS o desenvolvimento de um protótipo de um sensor digital para o monitoramento de ambientes. O objetivo do protótipo é realizar o monitoramento de um ambiente através da detecção de temperatura e umidade relativa coletadas por sensores DHT11, utilizando para recebimento e envio de comandos o protocolo de transmissão serial UART.

A parte de coleta de dados dos sensores DHT11 já foi desenvolvida em Verilog (linguagem de descrição de Hardware) e programada na FPGA Cyclone IV, e pode ser analisada no repositório [repAntigo](https://github.com/juserrrrr/DigitalSensorQuery). Neste antigo repositório, a interface com o usuário foi desenvolvida na linguagem C e era dada por meio de dois terminais Linux, um para visualização e outro para envio de comandos.

Para este projeto, foi solicitado o desenvolvimento de uma IHM (Interface Homem-Máquina) que apresente em um display LCD as informações do sensor desenvolvido. A interface deve substituir a que foi desenvolvida em linguagem C, atendendo aos mesmos requisitos. O protótipo dessa interface será embutido em um computador de placa única (SBC), mas especificamente na Orange Pi, e seu código deve ser escrito em Assembly para arquitetura ARMv7.

Este projeto resulta em um sistema capaz de receber e enviar comandos de requisições do usuário por meio de uma interface com um display LCD e botões e monitorar o ambiente, fornecendo dados como temperatura e umidade atual. As próximas seções abordarão em mais detalhes as metodologias empregadas, a descrição do projeto, resultados e testes.


## Metodologia
      
## Descrição do Projeto:
Para desenvolvimento do projeto, foi seguido esta ordem de prioridade no código:
![Ordem de desenvolvimento](https://github.com/juserrrrr/SensorQueryInterface/blob/ce1469873460d11d46e8abbea3d1f5fb7696643e/Blank%20diagram%20-%20Page%201.png)


Para manipulação de memória de dispositivos em sistemas Linux, como é o caso da Orange Pi, precisamos liberar as operações de leitura e gravação em arquivos especiais no diretório "/dev". Depois, fazemos os mapeamentos dos Pinos que utilizamos no protótipo que são os GPIOs, CCU e UART. Mapeados os pinos, podemos configurá-los e setar suas direções para OUTPUT ou INPUT. Depois é configurado o CCU e a UART e inicializado o display. Essas etapas serão explicadas detalhadamente nas seções posteriores.

O fluxo do programa pode ser visto na figura abaixo:
![Fluxo do programa](https://github.com/juserrrrr/SensorQueryInterface/blob/eb957d2f7a3f2744cba2d84afd9683bbc94690fd/Blank%20diagram%20-%20Page%201%20(2).png)

A tela inicial é a de escolha do sensor e comando, nela o usuário escolhe qual sensor vai ser requisitado e qual comando escolhido. Após essa escolha, ele será direcionado para tela das respostas imediatas, como Status do Sensor e Temperatura/Umidade atual. Se não foi requisitado nenhuma resposta imediata, aparece uma tela de Aguardando. Se na tela dos imediatos for pressionado o botão esquerdo, o usuário irá para a última tela das respostas contínuas; se o botão for o central, irá para a primeira tela dos contínuos; e sempre que apertar o botão direito, voltará para escolha do sensor e comando.

Na tela das temperaturas e umidades contínuas, sempre que o usuário estiver na última tela
e apertar o botão central, ele retorna para a tela das respostas imediatas, e sempre que estiver na primeira tela e apertar o botão esquerdo, ele também retorna para a tela das respostas imediatas. Só retorna para a escolha do sensor e comando se apertar o botão direito.

Nas telas dos contínuos, ao apertar o botão central, o usuário caminha para “frente”, visualizando dos sensores 0 ao 32; ao apertar o botão esquerdo, ele segue o caminho contrário, do sensor 32 ao 0.


## Resultados e análise dos testes
## LCD
## Funcionamento
Foi utilizado o controlador de display de cristal líquido (LCD) HD44780U, que consegue exibir caracteres alfanuméricos e símbolos. Ele pode ser configurado para controlar o LCD com um processador de 4 ou 8 bits. O HD44780U possui compatibilidade de função de pino com o HD44780S, possui ROM de gerador de caracteres estendida para um total de 240 fontes de caracteres. Além disso, pode exibir até uma linha de 8 caracteres ou duas linhas de 8 caracteres.

Para protótipo, o display LCD utilizado deve ser configurado para uma interface de 4 bits e com duas linhas de 8 caracteres cada.

## Pinagem
Após o mapeamento, conseguimos assim configurar os pinos do LCD e setar as suas direções (INPUT ou OUTPUT). No caso dos pinos usados no projeto, só foram de OUTPUT.

A pinagem do HD44780U é a seguinte:

1. VSS - Terra
2. VDD - Alimentação
3. V0 - Tensão de contraste
4. RS - Seleção de registro (0 para instruções, 1 para dados)
5. R/W - Leitura/Gravação (0 para gravação, 1 para leitura)
6. E - Habilitação do display
7. DB0 - Dado de barramento de 8 bits
8. DB1 - Dado de barramento de 8 bits
9. DB2 - Dado de barramento de 8 bits
10. DB3 - Dado de barramento de 8 bits
11. DB4 - Dado de barramento de 8 bits
12. DB5 - Dado de barramento de 8 bits
13. DB6 - Dado de barramento de 8 bits
14. DB7 - Dado de barramento de 8 bits

Os pinos 1, 2 e 3 são usados para alimentação e contraste, enquanto os pinos 4 a 14 são usados para comunicação. O pino R/W está sempre recebendo nível lógico alto, ou seja, só conseguimos fazer escrita no display. Como a configuração é de 4 bits de dados, o LCD utilizado não tem os pinos DB0, DB1, DB2 e DB3, somente do DB4 ao DB7.

Para enviar uma instrução ao display, precisa-se setar o valor de RS para 0, setar os bits de dados para os dados de barramento e ativar o pino de enable. Da mesma forma acontece para enviar um dado ao display, como um caractere ou dígito, só muda o valor de RS que deve ser 1.

## Tempo de Enable
O pino de Enable é utilizado para sinalizar a transmissão de dados dos outros pinos para o display. A cada envio de dados, devemos acionar o Enable.

Para usar o Enable, deve-se esperar um tempo mínimo de 60 ns (tAS) entre a setagem do pino RS e a subida de sinal do Enable. Depois o sinal de Enable é mantido em alta por um tempo mínimo de 450 ns (PWEH); após este tempo, o sinal pode retomar ao valor 0 (LOW). Entre uma borda de subida do Enable e outra, deve-se esperar um tempo mínimo de 1000 ns (tcycE).

Dentro do arquivo codesLCD.s, tem uma macro que aciona o Enable. Ela é invocada a cada vez que queremos enviar os dados.

![Tempo Enable](https://github.com/juserrrrr/SensorQueryInterface/blob/046a89fd62bedb22f2f0a5187745b93a0e264219/tempo%20enable.png)
![Tempo Enable1](https://github.com/juserrrrr/SensorQueryInterface/blob/046a89fd62bedb22f2f0a5187745b93a0e264219/tempo%20enable1.png)

## Inicialização
Entendo o funcionamento, as pinagens e os tempos de Enable, podemos assim partir para a parte de inicialização do display. Para utilizar o display devemos antes inicializá-lo, que é basicamente configurá-lo para o nosso propósito de uso.

O processo de inicialização pode ser visto na imagem abaixo:

![Init](https://github.com/juserrrrr/SensorQueryInterface/blob/dfbb6251106d87d957d39633164ab68cfb4f2d77/inicializacao.png)
![Init1](https://github.com/juserrrrr/SensorQueryInterface/blob/dfbb6251106d87d957d39633164ab68cfb4f2d77/inicializacao1.png)

O processo de inicialização pode ser feito em duas etapas: a primeira etapa é a inicialização de hardware, que envolve a alimentação do controlador e a espera de um tempo mínimo para que ele se estabilize. Essa etapa envolve os três blocos de bits iniciais, juntamente com os tempos de 15 ms, 4.1 ms e 100 us.

A segunda etapa é a inicialização de software, que envolve a configuração dos parâmetros do controlador, como o número de linhas do display, o tamanho dos caracteres e a posição do cursor. 

Dentro do arquivo codesLCD.s, há uma macro chamada “initialize’ que deve ser chamada uma única vez no código antes de usar o display. Ela que realiza a inicialização e configuração do LCD.

## Escrita das telas
Para a escrita de um caractere no display, basta enviarmos seu código binário em ASCII. A tabela ASCII é usada pelo HD44780U para mapear os códigos dos caracteres para os valores correspondentes em sua memória interna, permitindo que o controlador exiba caracteres alfanuméricos e símbolos no display, como pode ser visto na imagem abaixo.
![ascii](https://github.com/juserrrrr/SensorQueryInterface/blob/b0ca550e366a5af1454874ec5ef0c4820273ada0/ascii.png)

No arquivo codesLCD.s, há uma função “instructionCode” que recebe como parâmetro os 9 bits correspondentes aos pinos RS e os 8 de dados. Essa função envia inicialmente para o pino RS um bit indicando se vai ser uma instrução (mover cursor/display, limpar display, etc…) ou se vai ser uma transmissão de 1 byte ASCII para escrita. Depois ele parte para o envio dos nibbles (4 bits). Envia 4 bits mais significativos, ativa o Enable, depois envia os outros 4 bits menos significativos. Resumidamente, essa função serve para setar algumas funcionalidades do display e para escrever caracteres ASCII.

No mesmo arquivo, há uma função “writeString” que realiza a escrita de strings na tela do display. A cada chamada dessa função, ela limpa o display e escreve uma nova tela nele. Para usá-la, deve ser escrita na seção .data do arquivo main.s uma label com o nome da tela e duas linhas de Strings, como no exemplo abaixo:

![boas_vindas](https://github.com/juserrrrr/SensorQueryInterface/blob/41df0045b49d04ec156e08ae5c6dc5b9a1700289/boas_vindas.png)

Deve-se escrever .ascii na primeira linha, porque ao passar um char para um registrador, ele interpreta o seu binário em ASCII. O “\n” é utilizado para identificar que acabou a primeira linha. Deve-se escrever .asciz na segunda linha, pelos mesmos motivos da primeira linha, só que o Z indica que aquela String tem o caractere “\0” que indica o término de String.

O algoritmo do “writeString” funciona da seguinte forma:
Passe para o registrador r5 o endereço da tela no .data;
O algoritmo vai pegar o endereço base da tela (primeiro caractere) e chamar a “intructionCode” para imprimi-lo no display;
Depois vai percorrer o próximo endereço (próximo caractere) e imprimí-lo na próxima posição do display e assim sucessivamente até encontrar o “\n”;
Assim, pula a linha do display e continua a escrever até encontrar o “\0”.

No arquivo control.s tem a lógica de controle da tela de envio de comando e sensor, ela utiliza as funções de “writeString” e “instructionCode”. 

![sensorComando](https://github.com/juserrrrr/SensorQueryInterface/blob/41df0045b49d04ec156e08ae5c6dc5b9a1700289/sensorComando.png)

Já no arquivo windowsLCD.s tem a lógica das telas de respostas imediatas e das telas das respostas contínuas.

Exemplos de telas com respostas imediatas:

![tempAtual](https://github.com/juserrrrr/SensorQueryInterface/blob/41df0045b49d04ec156e08ae5c6dc5b9a1700289/tempAtual.png)
![status](https://github.com/juserrrrr/SensorQueryInterface/blob/41df0045b49d04ec156e08ae5c6dc5b9a1700289/status.png)

Exemplo de tela com resposta contínua:

![continuo](https://github.com/juserrrrr/SensorQueryInterface/blob/41df0045b49d04ec156e08ae5c6dc5b9a1700289/continuo.png)

## Conclusão

## Referências

## Autores

- José Gabriel de Almeida Pontes
- Luis Guilherme Nunes Lima
- Pedro Mendes
- Thiago Pinto Pereira Sena
