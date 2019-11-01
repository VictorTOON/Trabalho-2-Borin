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


#Configurar o GPT para gerar interrupção após 1 ms;
#Configurar o torque dos dois motores para zero;
#Configurar as articulações da cabeça do Uóli para a posição natural (Base = 31, Mid = 80, Top = 78);
#Configurar o tratamento de interrupções;
_start:
#GPT:


#Parametros: nenhum
#Retorno: a0: Valor obtido na leitura do sensor; -1 caso nenhum objeto tenha sido detectado a menos de 600 centímetros.
read_ultrasonic_sensor:
la t0, 0xFFFF0020
sw zero, 0(t0) # 
#TODO: interromper até FFFF0020 ter o valor 1 e pegar os objetos do sensor


delay:
    
    #empilha
    addi sp, sp, -4
    sw ra, 0(sp)

    jal time_now

    #desempilha
    lw ra, 0(sp)
    addi sp, sp, 4

    addi s1, a0, 0; # s1 = a0 + 0 #tempo de referencia
    li s0, 0 #tempo_atual=0
    li s9, 1
    while:
        #empilha
        addi sp, sp, -4
        sw ra, 0(sp)

        jal time_now

        #desempilha
        lw ra, 0(sp)
        addi sp, sp, 4

        addi s0, a0, 0; # s0 = a0 + 0
        sub t0, s0, s1 # t0 = s0 - s1
        blt t0, s9, while # if t0 < 1 then target

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

buffer_timeval: .skip 12
buffer_timerzone: .skip 12
