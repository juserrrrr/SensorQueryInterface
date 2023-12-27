# SensorQueryInterface

## Introdução
O acompanhamento remoto de ambientes fundamenta-se primordialmente no paradigma da Internet das Coisas (IoT). A transformação introduzida pelo mercado de IoT está reconfigurando a economia global de maneira extraordinária, ao proporcionar maior eficiência, estimular inovações e impulsionar melhorias significativas em diversos setores. De acordo com Perles et al. (2018), a conservação preventiva do patrimônio cultural, como obras de arte e artefatos históricos, é aprimorada hoje através da gestão de dados coletados por sensores eletrônicos

Com o crescimento do mercado de Internet das Coisas (IoT), uma empresa que deseja ingressar nesse setor solicitou aos estudantes de Engenharia da Computação da UEFS o desenvolvimento de um protótipo de um sensor digital para o monitoramento de ambientes. O objetivo do protótipo é realizar o monitoramento de um ambiente através da detecção de temperatura e umidade relativa coletadas por sensores DHT11, utilizando para recebimento e envio de comandos o protocolo de transmissão serial UART.

A parte de coleta de dados dos sensores DHT11 já foi desenvolvida em Verilog (linguagem de descrição de Hardware) e programada na FPGA Cyclone IV, e pode ser analisada no repositório X. Neste antigo repositório, a interface com o usuário foi desenvolvida na linguagem C e era dada por meio de dois terminais Linux, um para visualização e outro para envio de comandos.

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

## Conclusão

## Referências

## Autores

- José Gabriel de Almeida Pontes
- Luis Guilherme Nunes Lima
- Pedro Mendes
- Thiago Pinto Pereira Sena
