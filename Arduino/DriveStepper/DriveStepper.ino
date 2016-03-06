/*
 * MotorKnob
 *
 * A stepper motor follows the turns of a potentiometer
 * (or other sensor) on analog input 0.
 *
 * http://www.arduino.cc/en/Reference/Stepper
 * This example code is in the public domain.
 */

#include <Stepper.h>

// change this to the number of steps on your motor
#define STEPS 64

// create an instance of the stepper class, specifying
// the number of steps of the motor and the pins it's
// attached to
Stepper stepper(STEPS, 8, 9, 10, 11);

// the previous reading from the analog input
int previous = 0;
int i = 0;

void setup() {
  // set the speed of the motor to 30 RPMs
  stepper.setSpeed(50);
  
}

void loop() {
  // get the sensor value
  int val = analogRead(0);
  Serial.println(val);
  // move a number of steps equal to the change in the
  // sensor reading
  if( i < 10000){
    stepper.step(val - previous);
  }
  else if (i >= 10000 && i < 20000){
    stepper.step(previous - val);
  }

  else{
    i = 0;
  }

  previous = val;
  i++;

  
  //stepper.step(0);
  //delay(2000);
  //stepper.step(200);
  //delay(2000);
  //stepper.step(0);
  //delay(2000);
  
}
