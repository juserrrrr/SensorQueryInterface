@ Macro para aguardar um tempo em segundos e nanosegundos
@ R0 = Tempo em segundos
@ R1 = Tempo em nanosegundos
.macro nanoSleep time
    ldr r0, =\time
    .ltorg
    add r1, r0, #4  
    mov r7, #sys_nanosleep
    svc 0
.endm

.data
    remainingEnableTime:    .word 0         @Segundos
                            .word 600       @Nano Segundos

    totalLoadingTimeRs:     .word 0         @Segundos
                            .word 60        @Nano Segundos

    totalEnableTimeHigh:    .word 0         @Segundos
                            .word 450       @Nano Segundos

    awaitInstruction:       .word 0         @Segundos
                            .word 40000     @Nano Segundos

    awaitInstructionHome:   .word 0         @Segundos
                            .word 1600000    @Nano Segundos

    oneSecond:              .word 1         @Segundos
                            .word 0         @Nano Segundos

    twoSeconds:             .word 2         @Segundos
                            .word 0         @Nano Segundos
    zeMeMama:
			     .word 0
			     .word 105000000
    zeMeMama2:
    			     .word 0
			     .word 5500000
    zeMeMama3:
    			     .word 0 
    			     .word 100000
