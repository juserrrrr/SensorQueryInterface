@R5: Tela da temperatura ou umidade atual
showSensorValue:
  push {r2, r3, r4, r5, lr}
  bl writeString @Escreve a tela de boas vindas

  mov r2, #0b111000110
  mov r3, #0
  bl instructionCode	
  
  ldr r4, =now_address
  ldr r4, [r4]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode

  mov r2, #0b111001010 @Mover cursor para escolha do Sensor
  mov r3, #0
  bl instructionCode	
  
  ldr r4, =now_value
  ldr r4, [r4]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode
  pop {r2, r3, r4, r5, pc}

@R5: Tela da sensor OK ou sensor não ok
showSensorStatus:
  push {r2, r3, r4, r5, lr}
  bl writeString @Escreve a tela de boas vindas

  mov r2, #0b110000110
  mov r3, #0
  bl instructionCode	
  
  ldr r4, =now_address
  ldr r4, [r4]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode

  pop {r2, r3, r4, r5, pc}

@R7: valor inicial da dupla de continuos, ex: 0 mostra o 0 e o 1
showTwoConstant:
  push {r2, r3, r4, r6, r7, lr}

  mov r2, #0b110000000 @Seta o cursor para a primeira posição da linha
  mov r3, #0
  bl instructionCode	

  mov r4, r7          @ carregando o endereco que sera printado
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0 @Primeiro dígito
  bl instructionCode

  mov r3, #0
  mov r2, r1 @Segundo dígito
  bl instructionCode

  mov r2, #0b110000110 @ cursor para a sexta posição
  mov r3, #0
  bl instructionCode

  mov r6, #4 @Offset de 4 bytes na memória
  mul r6, r7, r6

  ldr r4, =last_temp
  ldr r4, [r4, r6]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode

  mov r2, #0b110001101 @ Cursor para linha 1, posição 13
  mov r3, #0
  bl instructionCode

  ldr r4, =last_hum
  ldr r4, [r4, r6]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode

  @ linha de baixo
  add r7, #1

  mov r2, #0b111000000 @ cursor move para a primeira posição da segunda linha
  mov r3, #0
  bl instructionCode	

  mov r4, r7          @ carregando o endereco que sera printado
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode

  mov r2, #0b111000110 @ cursor move para sexta posição na segunda linha
  mov r3, #0
  bl instructionCode

  mov r6, #4 @Offset de 4 bytes da memória
  mul r6, r7, r6

  ldr r4, =last_temp
  ldr r4, [r4, r6]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode

  mov r2, #0b111001101 @cursor move para a 13 posição da segunda linha
  mov r3, #0
  bl instructionCode

  ldr r4, =last_hum
  ldr r4, [r4, r6]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode
  
  pop {r2, r3, r4, r6, r7, pc}

@R5: Tela da sensor OK ou sensor não ok
showActivate:
  push {r2, r3, r4, r5, lr}
  bl writeString @Escreve a tela de boas vindas

  mov r2, #0b111000110
  mov r3, #0
  bl instructionCode	
  
  ldr r4, =now_address
  ldr r4, [r4]
  bl convertBinaryToAscii

  mov r3, #0
  mov r2, r0
  bl instructionCode

  mov r3, #0
  mov r2, r1
  bl instructionCode

  pop {r2, r3, r4, r5, pc}
