#include <CurieBle.h>

const int connectedLedPin = 13;

BLEPeripheral blePeripheral;
BLEService keylessEntryService("CADE0000-F78F-4F65-846A-C4DC27285BA3"); // Custom Service
BLEService deviceInformationService("180A");
BLEUnsignedLongCharacteristic keylessEntryMobileDeviceKeyChar("CADE0001-F78F-4F65-846A-C4DC27285BA3", BLEWrite);
BLEUnsignedLongCharacteristic keylessEntryStatusCodeChar("CADE0002-F78F-4F65-846A-C4DC27285BA3", BLERead | BLENotify);


void setup() {
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
      
    }

    // When the central disconnects, turn off the connected led
    digitalWrite(connectedLedPin, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  }
}

void connectedHandler(BLECentral &central) {
  Serial.print("Connected, central: ");
  Serial.println(central.address());

  keylessEntryStatusCodeChar.setValue(0x00);
}

void disconnectedHandler(BLECentral &central) {
  Serial.print("Disconnected, central: ");
  Serial.println(central.address());
}

void keylessEntryMobileDeviceCharacteristicUpdateHandler(BLECentral& central, BLECharacteristic& characteristic) {
  Serial.print("KeylessEntryMobileDeviceCharacteristic updated: ");
  Serial.println((const char *)characteristic.value());
}
