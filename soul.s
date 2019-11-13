# .globl read_ultrasonic_sensor
# .globl set_servo_angles 
# .globl set_engine
# .globl read_gps 
# .globl read_gyroscope 
# .globl get_current_time 
# .globl set_current_time
# .globl write
.globl _start
#O que rola aqui é que precisamo colocar as funcoes no globl pra elas serem globais
#TODO: REMOVER OS CODIGOS COMENTADOS

#------------------------------------------------------------------------------------------------------------------------#
#Configurar o tratamento de interrupções;
#Configurar o GPT para gerar interrupção após 1 ms;
#Configurar o torque dos dois motores para zero;
#Configurar as articulações da cabeça do Uóli para a posição natural (Base = 31, Mid = 80, Top = 78);
_start:
#Configurar o tratador de interrupções
    la t0, tratador_interrupcoes
    csrw mtvec, t0
#Configurar o torque dos dois motores para zero;
    la t0, 0xFFFF0018
    sh zero, 0(t0) #coloco o motor 2 pra zero

    la t0, 0xFFFF001A
    sh zero, 0(t0) #coloco o motor 1 pra zero
#Configurar a cabeca do uóli
    la t0, 0xFFFF001C
    li t1, 78
    sb t1, 0(t0) # carrego 78 no servo top

    la t0, 0xFFFF001D
    li t1, 80
    sb t1, 0(t0) # carrego 80 no servo mid

    la t0, 0xFFFF001E
    li t1, 31
    sb t1, 0(t0) # carrego 31 no servo bot
#GPT:
    la t0, 0xFFFF0100
    li t1, 100 #carrego o 100
    sw t1, 0(t0) #salvo no endereço de memoria

#------------------------------------------------------------------------------------------------------------------------#
#Habilitar interrupções;
#Configurar a pilha do usuário e do sistema;
#Mudar para o modo usuário;
#Desviar o fluxo para a função main do programa do usuário;
aplicacao_de_controle:
#Habilitando interrupções globais
    csrr t0, mstatus #Bit 7
    ori t0, t0, 0x80
    csrw mstatus, t0

#Habilitando interrupções externas
    csrr t0, mie #Bit 11
    ori t0, t0, 0x800
    csrw mie, t0
#Ajustando o mscratch
    la t0, reg_buffer
    csrw mscratch, t0 
#Mudar pro modo usuário
    csrr t0, mstatus #seta os bits 11 e 12
    li t1, ~0x1800
    and t0, t0, t1 #isso aqui vai ter o mstatus antigo com o 11 e o 12 sendo 0
    csrw mstatus, t0 #guardo de volta

    la t0, main
    csrw mepc, t0

    mret #me retorna pra func do usuario, que seria a main

#------------------------------------------------------------------------------------------------------------------------#
#Parametros: nenhum
#Retorno: a0: Valor obtido na leitura do sensor; -1 caso nenhum objeto tenha sido detectado a menos de 600 centímetros.
read_ultrasonic_sensor:
la t0, 0xFFFF0020
sw zero, 0(t0) # 
RUS_While:
    # #empilha
    # addi sp, sp, -4
    # sw ra, 0(sp)

    # jal delay

    # #desempilha
    # lw ra, 0(sp)
    # addi sp, sp, 4

    la t0, 0xFFFF0020
    li t1, 1

    bne t0, t1, RUS_While # if t0 != t1 then RUS_While

la t0, 0xFFFF0024
lw t0, 0(t0)
li t1, 601

blt t0, t1, RUS_600menor # if t0 < t1 then RUS_600menor
li a0, -1
ret

RUS_600menor:
mv  a0, t0 # a0 = t0
ret

#------------------------------------------------------------------------------------------------------------------------#
#parametros:
#a0: id do servo a ser modificado. 
#a1: ângulo para o servo.
#Retorno: 
#a0: -1, caso o ângulo de um dos servos seja inválido (neste caso, a operação toda deve
#ser cancelada e nenhum ângulo definido). -2, caso o id do servo seja inválido. Caso contrário, retorna 0.
set_servo_angles:
    li t0, 0xFFFF001F
    sub t0, t0, a0 # t0 = t0 - a0 #isso deve cair no endereço correto do servo

    li t1, 1
    beq a0, t1, SSA_id1; # if a0 == t1 then SSA_id1

    li t1, 2
    beq a0, t1, SSA_id2; # if a0 == t1 then SSA_id2

    li t1, 3
    beq a0, t1, SSA_id3; # if a0 == t1 then SSA_id3
    
    j SSA_idInvalid

SSA_id1:
    li t1, 16
    blt a1, t1, SSA_angleInvalid # if a1 < 16 then SSA_angleInvalid

    li t1, 116
    bgt a1, t1, SSA_angleInvalid # if a1 > 116 then SSA_angleInvalid
    
    sb a1, 0(t0) # isso aqui guarda o valor do angulo

    li a0, 0
    ret

SSA_id2:
    li t1, 52
    blt a1, t1, SSA_angleInvalid # if a1 < 52 then SSA_angleInvalid

    li t1, 90
    bgt a1, t1, SSA_angleInvalid # if a1 > 90 then SSA_angleInvalid
    
    sb a1, 0(t0) # isso aqui guarda o valor do angulo

    li a0, 0
    ret

SSA_id3:
    li t1, 0
    blt a1, t1, SSA_angleInvalid # if a1 < 0 then SSA_angleInvalid

    li t1, 156
    bgt a1, t1, SSA_angleInvalid # if a1 > 156 then SSA_angleInvalid
    
    sb a1, 0(t0) # isso aqui guarda o valor do angulo

    li a0, 0
    ret

SSA_idInvalid:
    li a0, -2
    ret

SSA_angleInvalid:    
    li a0, -1
    ret

#------------------------------------------------------------------------------------------------------------------------#

#parametros:
#a0: id do motor a ser modificado. 
#a1: torque do motor.
#Retorno: 
#a0: a0: -1, caso o id do motor seja inválido. 0, caso contrário. 
#A chamada de sistema não deve verificar a validade dos valores de torque.
set_engine:
    li t0, 0xFFFF001A

    li t1, 0
    beq a0, t1, SET_id0; # if a0 == t1 then SET_id0

    li t1, 1
    beq a0, t1, SET_id1; # if a0 == t1 then SET_id1
    
    j SET_idInvalid

SET_id0:
    sh a1, 0(t0) # isso aqui guarda o valor do torque

    li a0, 0
    ret

SET_id1:

    addi t0, t0, -2 # t0 = t0 - 2 #isso deve cair no endereço correto do motor
    sh a1, 0(t0) # isso aqui guarda o valor do torque

    li a0, 0
    ret

SET_idInvalid:
    li a0, -1
    ret

#------------------------------------------------------------------------------------------------------------------------#

#parametros:
#a0: Endereço do registro (com três valores inteiros) para armazenar as coordenadas (x, y, z);
read_gps:
    #ler X,Y,Z e angulo:
    la t0, 0xFFFF0004
    sw zero, 0(t0) # 

    RGPS_While:   
        # #empilha
        # addi sp, sp, -4
        # sw ra, 0(sp)

        # jal delay

        # #desempilha
        # lw ra, 0(sp)
        # addi sp, sp, 4

        la t0, 0xFFFF0020
        li t1, 1

        bne t0, t1, RGPS_While # if t0 != t1 then RGPS_While

    la t1, 0xFFFF0008
    sw t1, 0(a0)

    la t1, 0xFFFF000C
    sw t1, 4(a0)

    la t1, 0xFFFF0010
    sw t1, 8(a0)

    ret
#------------------------------------------------------------------------------------------------------------------------#
#parametros:
#a0: Endereço do registro (com três valores inteiros) para armazenar os ângulos de Euler (x, y, z);
read_gyroscope:
    #ler X,Y,Z e angulo:
    la t0, 0xFFFF0004
    sw zero, 0(t0) # 

    RGYRO_While:   
        # #empilha
        # addi sp, sp, -4
        # sw ra, 0(sp)

        # jal delay

        # #desempilha
        # lw ra, 0(sp)
        # addi sp, sp, 4

        la t0, 0xFFFF0020
        li t1, 1

        bne t0, t1, RGYRO_While # if t0 != t1 then RGYRO_While

    #mascara
    la t0, 0xFFFF0014
    lw t1, 0(t0) #

    andi t2, t1, 0x3FF00000
    srli t2, t2, 20
    sw t2, 0(a0) # coloca o X

    andi t2, t1, 0xFFC00
    srli t2, t2, 10
    sw t2, 4(a0) # coloca o Y

    andi t2, t1, 0x3FF
    sw t2, 8(a0) # coloca o Z
    
    ret
#------------------------------------------------------------------------------------------------------------------------#
#retorno: a0:tempo do sistema, em milissegundos
get_current_time :
    la t0, internal_clock
    lw a0, 0(t0)
    ret
#------------------------------------------------------------------------------------------------------------------------#
#parâmetro: a0: tempo do sistema, em milissegundos
set_current_time:
    la t0, internal_clock
    sw a0, 0(t0)
    ret
#------------------------------------------------------------------------------------------------------------------------#
#parametros:a0: Descritor do arquivo 
#a1: Endereço de memória do buffer a ser escrito. 
#a2: Número de bytes a serem escritos.
#retorno: a0: Número de bytes efetivamente escritos.
write:
    li a0, 0
    write_for:
        bge a0, a2, write_continue
        #imprime o role
        la t0, 0xFFFF0109
        lw t1, 0(a1)
        sw t1, 0(t0) # 

        la t0, 0xFFFF0108
        li t1, 1
        sw t1, 0(t0)
        
        loop_UART_Delay:


            la t0, 0xFFFF0108
            lw t1, 0(t0)
            bnez t1, loop_UART_Delay #Brench not equals zero

        addi a0, a0, 1; # a0 = a0 + 1
        addi a1, a1, 1; # a1 = a1 + 1
        j write_for

    write_continue:

    ret
#------------------------------------------------------------------------------------------------------------------------#
tratador_interrupcoes:
    csrrw a6, mscratch, a6
    #empilha
    sw ra, 0(a6)
    sw a1, 4(a6)
    sw a2, 8(a6)
    sw a3, 12(a6)
    sw a4, 16(a6)
    sw a5, 20(a6)
    sw a0, 24(a6)
    sw t0, 28(a6)
    sw t1, 32(a6)
    sw t2, 36(a6)
    sw t3, 40(a6)
    sw t4, 44(a6)
    sw t5, 48(a6)
    sw t6, 52(a6)

    csrr a1, mcause
    li a2, 0x8000000B
    bne a1, a2, not_GPT; # if a1 == a2 then not_GPT
        la a1, internal_clock
        lw a2, 0(a1) #
        addi a2, a2, 100; # a2 = a2 + 100
        sw a2, 0(a1) # 

        la a1, 0xFFFF0100 #
        li a2, 100 # a2 = 100
        sw a2, 0(a1)
        
        la a1, 0xFFFF0104
        sb zero, 0(a1)
        
        #desempilha
        lw ra, 0(a6)
        lw a1, 4(a6)
        lw a2, 8(a6)
        lw a3, 12(a6)
        lw a4, 16(a6)
        lw a5, 20(a6)
        lw a0, 24(a6)
        lw t0, 28(a6)
        lw t1, 32(a6)
        lw t2, 36(a6)
        lw t3, 40(a6)
        lw t4, 44(a6)
        lw t5, 48(a6)
        lw t6, 52(a6)
        csrrw a6, mscratch, a6
        
        mret
    not_GPT:
    
    li a1, 64
    bne a7, a1, not_64; # if t0 == t1 then not_64
    #desempilha
    lw a0, 24(a6)
    lw a1, 4(a6)#pego de volta os parametros da funcao
    lw a2, 8(a6)
    jal write  # jump to write and save position to ra
    #empilha dnv
    sw a0, 24(a6)
    sw a1, 4(a6)#empilho de volta
    sw a2, 8(a6)
    j retorno_interrup
    not_64:
    
    li a1, 22
    bne a7, a1, not_22; # if t0 == t1 then not_22
    #desempilha
    lw a0, 24(a6)
    jal set_current_time  # jump to set_current_time and save position to ra
    j retorno_interrup
    not_22:

    li a1, 21
    bne a7, a1, not_21; # if t0 == t1 then not_21
    jal get_current_time   # jump to get_current_time  and save position to ra
    #empilha dnv
    sw a0, 24(a6)
    j retorno_interrup
    not_21:

    li a1, 20
    bne a7, a1, not_20; # if t0 == t1 then not_20
    #desempilha
    lw a0, 24(a6)
    jal read_gyroscope  # jump to read_gyroscope and save position to ra
    j retorno_interrup
    not_20:

    li a1, 19
    bne a7, a1, not_19; # if t0 == t1 then not_19
    #desempilha
    lw a0, 24(a6)
    jal read_gps  # jump to read_gps and save position to ra
    j retorno_interrup
    not_19:

    li a1, 18
    bne a7, a1, not_18; # if t0 == t1 then not_18
    #desempilha
    lw a0, 24(a6)
    lw a1, 4(a6)#pego de volta os parametros da funcao
    jal set_engine  # jump set_engine and save position to ra
    #empilha dnv
    sw a0, 24(a6)
    j retorno_interrup
    not_18:

    li a1, 17
    bne a7, a1, not_17; # if t0 == t1 then not_17
    #desempilha
    lw a0, 24(a6)
    lw a1, 4(a6)#pego de volta os parametros da funcao
    jal set_servo_angles  # jump set_servo_angles and save position to ra
    #empilha dnv
    sw a0, 24(a6)
    j retorno_interrup
    not_17:

    li a1, 16
    bne a7, a1, not_16; # if t0 == t1 then not_16
    jal read_ultrasonic_sensor  # jump read_ultrasonic_sensor and save position to ra
    #empilha dnv
    sw a0, 24(a6)
    j retorno_interrup
    not_16:

    retorno_interrup:

        csrr a1, mepc
        addi a1, a1, 4
        csrs mepc, a1

        #desempilha
        lw ra, 0(a6)
        lw a1, 4(a6)
        lw a2, 8(a6)
        lw a3, 12(a6)
        lw a4, 16(a6)
        lw a5, 20(a6)
        lw a0, 24(a6)
        lw t0, 28(a6)
        lw t1, 32(a6)
        lw t2, 36(a6)
        lw t3, 40(a6)
        lw t4, 44(a6)
        lw t5, 48(a6)
        lw t6, 52(a6)
        csrrw a6, mscratch, a6

        mret

#------------------------------------------------------------------------------------------------------------------------#
buffer_timeval: .skip 12
buffer_timerzone: .skip 12
internal_clock: .word 0