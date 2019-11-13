.globl set_torque
.globl set_engine_torque
.globl set_head_servo
.globl get_us_distance
.globl get_current_GPS_position
.globl get_gyro_angles
.globl get_time
.globl set_time
.globl puts


# /* 
#  * Sets both engines torque. The torque value must be between -100 and 100.
#  * Parameter: 
#  *   engine_1: Engine 1 torque
#  *   engine_2: Engine 2 torque
#  * Returns:
#  *   -1 in case one or more values are out of range
#  *    0 in case both values are in range
#  */
#int set_torque(int engine_1, int engine_2);
set_torque:
    mv t0, a0 # t0 = a0 torque da engine 1
    mv t1, a1 # t1 = a1 torque da engine 2

    li t2, 100
    li t3, -100

    blt t0, t3, STError # if t0 < t1 then STError
    bgt t0, t2, STError # if t0 > t1 then STError
    
    blt t1, t3, STError # if t0 < t1 then STError
    bgt t1, t2, STError # if t0 > t1 then STError

    li a0, 0 # a0 = 0
    mv a1, t0 # a1 = t0 coloco o torque daquela engine
    li a7, 18 #codigo da ecall
    ecall
    
    li a0, 1 # a0 = 1
    mv a1, t1 # a1 = t1 coloco o torque daquela engine
    li a7, 18 #codigo da ecall
    ecall

    li a0, 0
    ret

    STError:

        li a0, -1
        ret

# /* 
#  * Sets engine torque. Engine ID 0/1 identifies the left/right engine.
#  * The torque value must be between -100 and 100.
#  * Parameter: 
#  *   engine_id: Engine ID
#  *   torque: Engine torque
#  * Returns:
#  *   -1 in case the torque value is invalid (out of range)
#  *   -2 in case the engine_id is invalid
#  *    0 in case both values are valid
#  */
#int set_engine_torque(int engine_id, int torque);
set_engine_torque:
    li t2, 100
    li t3, -100

    blt a1, t3, SETError_Torque # if a1 < t3 then SETError_Torque
    bgt a1, t2, SETError_Torque # if a1 > t2 then SETError_Torque

    li a7, 18 #codigo da ecall
    ecall

    add a0, a0, a0; # a0 = a0 + a0 #caso a0 seja zero, o retorno vai ser zero, caso ele seja -1, o retorno deve ser -2
    ret
    SETError_Torque:

        li a0, -1
        ret
# /* 
#  * Sets the angle of three Servo motors that control the robot head. 
#  *   Servo ID 0/1/2 identifies the Base/Mid/Top servos.
#  * Parameter: 
#  *   servo_id: Servo ID 
#  *   angle: Servo Angle 
#  * Returns:
#  *   -1 in case the servo id is invalid
#  *   -2 in case the servo angle is invalid
#  *    0 in case the servo id and the angle is valid
#  */
# int set_head_servo(int servo_id, int angle);
set_head_servo:
    li a7, 17
    ecall

    #como os retornos estão trocados em relação ao soul, invertemos caso necessario
    beq a0, -1, SHSError_angle
    beq a0, -2, SHSError_id

    ret

    SHSError_angle:
        li a0, -2
        ret
    
    SHSError_id:
        li a0, -1
        ret

# /**************************************************************/
# /* Sensors                                                    */
# /**************************************************************/

# /* 
#  * Reads distance from ultrasonic sensor.
#  * Parameter: 
#  *   none
#  * Returns:
#  *   distance of nearest object within the detection range, in centimeters.
#  */
# unsigned short get_us_distance();
get_us_distance:
    li a7, 16
    ecall

    ret
# /* 
#  * Reads current global position using the GPS device.
#  * Parameter: 
#  *   pos: pointer to structure to be filled with the GPS coordinates.
#  * Returns:
#  *   void
#  */
# void get_current_GPS_position(Vector3* pos);
get_current_GPS_position:
    li a7, 19
    ecall

    ret

# /* 
#  * Reads global rotation from the gyroscope device .
#  * Parameter: 
#  *   pos: pointer to structure to be filled with the Euler angles indicated by the gyroscope.
#  * Returns:
#  *   void
#  */
# void get_gyro_angles(Vector3* angles);
get_gyro_angles:
    li a7, 20
    ecall

    ret
# /**************************************************************/
# /* Timer                                                      */
# /**************************************************************/

# /* 
#  * Reads the system time. 
#  * Parameter:
#  *   none
#  * Returns:
#  *   The system time (in milliseconds)
#  */
# unsigned int get_time();
get_time:
    li a7, 21
    ecall

    ret
# /* 
#  * Sets the system time.
#  * Parameter: 
#  *   t: the new system time.
#  * Returns:
#  *   void
#  */
# void set_time(unsigned int t);
set_time:
    li a7, 22
    ecall

    ret

# /**************************************************************/
# /* UART                                                       */
# /**************************************************************/

# /* 
#  * Writes a string to the UART. Uses the syscall write with file 
#  * descriptor 1 to instruct the SOUL to write the string to the UART.
#  * Parameter:
#  *   * s: pointer to the string.
#  * Returns:
#  *   void
#  */
# void puts(const char*);
puts:
    mv a1, a0 # a1 = a0
    li a0, 1

    #equanto o char for diferente de /0, a2++
        li a2, 0
        mv t0, a1

        puts_While:
        lb t1, 0(t0)
        beqz t1, puts_Continue
        addi a2, a2, 1
        addi t0, t0, 1
        j puts_While

    puts_Continue:
    li a7, 64
    ecall

    ret

