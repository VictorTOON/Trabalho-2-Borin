#include "api_robot.h"

int main(){
    set_head_servo(0, 90);
    set_torque(10, -10);
    short dist = get_us_distance();
    Vector3 position;
    get_current_GPS_position(&position);
    Vector3 gyro_angles;
    get_gyro_angles(&gyro_angles);
    set_time(200);
    int time = get_time();
    char teste[] = "testando";
    puts(teste);
}
