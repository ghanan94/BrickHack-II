#include <CurieBle.h>
#include <Stepper.h>
#include <Servo.h>

const int connectedLedPin = 13;

// change this to the number of steps on your motor
#define STEPS 64

// create an instance of the stepper class, specifying
// the number of steps of the motor and the pins it's
// attached to
Stepper stepper(STEPS, 8, 9, 10, 11);

// the previous reading from the analog input
int previous = 0;

Servo myservo;
int pos = 0;

BLEPeripheral blePeripheral;
BLEService keylessEntryService("CADE0000-F78F-4F65-846A-C4DC27285BA3"); // Custom Service
BLEService deviceInformationService("180A");
BLEUnsignedLongCharacteristic keylessEntryMobileDeviceKeyChar("CADE0001-F78F-4F65-846A-C4DC27285BA3", BLEWrite);
BLEUnsignedLongCharacteristic keylessEntryStatusCodeChar("CADE0002-F78F-4F65-846A-C4DC27285BA3", BLERead | BLENotify);
volatile bool authenticated = false;
volatile bool locked = false;

void setup() {
  //analogWrite(0, 255);
  
  // set the speed of the motor to 50 RPMs
  stepper.setSpeed(50);

  myservo.attach(12);
  myservo.write(60);
  
  // put your setup code here, to run once:
  Serial.begin(9600);    // initialize serial communication
  pinMode(connectedLedPin, OUTPUT);   // initialize the LED on pin 13 to indicate when a central is connected

  // set the local name peripheral advertises
  blePeripheral.setLocalName("Sandshrew");
  // set the UUID for the service this peripheral advertises
  blePeripheral.setAdvertisedServiceUuid(keylessEntryService.uuid());

  // add service and characteristic
  blePeripheral.addAttribute(keylessEntryService);
  blePeripheral.addAttribute(keylessEntryMobileDeviceKeyChar);
  blePeripheral.addAttribute(keylessEntryStatusCodeChar);
  blePeripheral.addAttribute(deviceInformationService);

  // assign event handlers for connected, disconnected to peripheral
  blePeripheral.setEventHandler(BLEConnected, connectedHandler);
  blePeripheral.setEventHandler(BLEDisconnected, disconnectedHandler);

  // assign event handler for characteristic
  keylessEntryMobileDeviceKeyChar.setEventHandler(BLEWritten, keylessEntryMobileDeviceCharacteristicUpdateHandler);

   /* Now activate the BLE device.  It will start continuously transmitting BLE
     advertising packets and will be visible to remote BLE central devices
     until it receives a new connection */
  blePeripheral.begin();
  Serial.println("Bluetooth device active, waiting for connections...");
}

void loop() {
  // put your main code here, to run repeatedly:

  // listen for BLE peripherals to connect:
  BLECentral central = blePeripheral.central();

  // if a central is connected to peripheral:
  if (central) {
    Serial.print("Connected to central: ");
    Serial.println(central.address());
    digitalWrite(connectedLedPin, HIGH); // turn on the LED to indicate the connection

    while (central.connected()) {
      if (authenticated && locked) {
        for(int i = 0; i < 250; i++) {
          //int val = analogRead(0);
          //Serial.println(val - previous);
          stepper.step(1);
          //previous = val;
        }
      
        myservo.write(115);
        delay(2000);     
        myservo.write(60);

        locked = false;
      }
    }

    // When the central disconnects, turn off the connected led
    digitalWrite(connectedLedPin, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());

    myservo.write(5);
    delay(2000);   
    myservo.write(60);
    locked = true;
    
    for(int i = 0; i < 250; i++) {
      //int val = analogRead(0);
      //Serial.println(previous - val);
      stepper.step(-1);
      //previous = val;
    }
  }
}

void connectedHandler(BLECentral &central) {
  Serial.print("Connected, central: ");
  Serial.println(central.address());

  authenticated = false;
  locked = true;
  keylessEntryStatusCodeChar.setValue(0x00);
}

void disconnectedHandler(BLECentral &central) {
  Serial.print("Disconnected, central: ");
  Serial.println(central.address());

  authenticated = false;
}

void keylessEntryMobileDeviceCharacteristicUpdateHandler(BLECentral& central, BLECharacteristic& characteristic) {
  Serial.print("KeylessEntryMobileDeviceCharacteristic updated: ");
  const char *str = (const char *)characteristic.value();
  Serial.println(str);

  if (strcmp(str, "San") == 0) {
    authenticated = true;
  } else {
    authenticated = false;  
  }
  
  /**/
}
