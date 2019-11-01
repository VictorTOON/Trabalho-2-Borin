.globl read_ultrasonic_sensor
.globl set_servo_angles 
.globl set_engine_torque 
.globl read_gps 
.globl read_gyroscope 
.globl get_time 
.globl set_time
.globl write
.globl _start
#O que rola aqui é que precisamo colocar as funcoes no globl pra elas serem globais

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
    li t1, 1 #carrego o 1
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
    #empilha
    addi sp, sp, -4
    sw ra, 0(sp)

    jal delay

    #desempilha
    lw ra, 0(sp)
    addi sp, sp, 4

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
set_engine_torque:
    li t0, 0xFFFF001A

    li t1, 0
    beq a0, t1, SET_id0; # if a0 == t1 then SET_id0

    li t1, 1
    beq a0, t1, SET_id1; # if a0 == t1 then SET_id1
    
    j SET_idInvalid

SET_id0:
    sb a1, 0(t0) # isso aqui guarda o valor do torque

    li a0, 0
    ret

SET_id1:

    addi t0, t0, -2 # t0 = t0 - 2 #isso deve cair no endereço correto do motor
    sb a1, 0(t0) # isso aqui guarda o valor do torque

    li a0, 0
    ret

SET_idInvalid:
    li a0, -1
    ret

#------------------------------------------------------------------------------------------------------------------------#

tratador_interrupcoes:
#TODO:

delay:
    #empilha
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)

    jal time_now

    #desempilha
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 12

    addi a2, a0, 0; # a2 = a0 + 0 #tempo de referencia
    li a1, 0 #tempo_atual=0
    li a3, 1
    while:
        #empilha
        addi sp, sp, -12
        sw ra, 0(sp)
        sw a0, 4(sp)
        sw a1, 8(sp)

        jal time_now

        #desempilha
        lw ra, 0(sp)
        lw a0, 4(sp)
        lw a1, 8(sp)
        addi sp, sp, 12

        addi a1, a0, 0; # a1 = a0 + 0
        sub t0, a1, a2 # t0 = a1 - a2
        blt t0, a3, while # if t0 < 1 then target

    ret

time_now:
  la a0, buffer_timeval
  la a1, buffer_timerzone
  li a7, 169 # chamada de sistema gettimeofday
  ecall
  la a0, buffer_timeval
  lw t1, 0(a0) # tempo em segundos
  lw t2, 8(a0) # fração do tempo em microssegundos
  li t0, 1000
  mul t1, t1, t0
  div t2, t2, t0 #t2 em milisegundos
  add a0, t2, t1
  ret
#------------------------------------------------------------------------------------------------------------------------#
buffer_timeval: .skip 12
buffer_timerzone: .skip 12
