/*
   Copyright (c) 2015 Intel Corporation.  All rights reserved.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/
#include <CurieBle.h>

/*
   This sketch example partially implements the standard Bluetooth Low-Energy Battery service.
   For more information: https://developer.bluetooth.org/gatt/services/Pages/ServicesHome.aspx
*/

/*  */
BLEPeripheral blePeripheral;       // BLE Peripheral Device (the board you're programming)
BLEService batteryService("180F"); // BLE Battery Service
BLEService deviceInformationService("180A");
BLEService heartRateService("180D");

// BLE Battery Level Characteristic"
BLEUnsignedCharCharacteristic batteryLevelChar("2A19", BLERead | BLEWrite | BLENotify);  // standard 16-bit characteristic UUID remote clients will be able to get notifications if this characteristic changes
BLEUnsignedLongCharacteristic heartRateChar("2A37", BLEWrite);                                                        

int oldBatteryLevel = 0;  // last battery level reading from analog input
long previousMillis = 0;  // last time the battery level was checked, in ms
String readString;
int batteryLevel = 0;

void handler1(BLECentral &central, BLECharacteristic &characteristic) {
  Serial.print("Input received: ");
  Serial.println((const char *)characteristic.value());
}

BLECharacteristicEventHandler ahandler1 = &handler1;
//BLEPeripheralEventHandler ahandler1 = &handler1;


void setup() {
  Serial.begin(9600);    // initialize serial communication
  pinMode(13, OUTPUT);   // initialize the LED on pin 13 to indicate when a central is connected

  /* Set a local name for the BLE device
     This name will appear in advertising packets
     and can be used by remote devices to identify this BLE device
     The name can be changed but maybe be truncated based on space left in advertisement packet */
  blePeripheral.setLocalName("Sandshrew");
  blePeripheral.setAdvertisedServiceUuid(deviceInformationService.uuid());  // add the service UUID
  blePeripheral.addAttribute(deviceInformationService);
  blePeripheral.addAttribute(batteryService);   // Add the BLE Battery service
  blePeripheral.addAttribute(batteryLevelChar); // add the battery level characteristic
  blePeripheral.addAttribute(heartRateService);
  blePeripheral.addAttribute(heartRateChar);
  batteryLevelChar.setValue(0);   // initial value for this characteristic
  heartRateChar.setValue(0);
  
  heartRateChar.setEventHandler(BLEWritten, ahandler1);
  //blePeripheral.setEventHandler(BLEDisconnected, ahandler1);

  /* Now activate the BLE device.  It will start continuously transmitting BLE
     advertising packets and will be visible to remote BLE central devices
     until it receives a new connection */
  blePeripheral.begin();
  Serial.println("Bluetooth device active, waiting for connections...");
}

void loop() {
  // listen for BLE peripherals to connect:
  BLECentral central = blePeripheral.central();

  

  // if a central is connected to peripheral:
  if (central) {
    Serial.print("Connected to central: ");
    // print the central's MAC address:
    Serial.println(central.address());
    // turn on the LED to indicate the connection:
    digitalWrite(13, HIGH);

    // check the battery level every 200ms
    // as long as the central is still connected:
    while (central.connected()) {
      long currentMillis = millis();
      // if 200ms have passed, check the battery level:
      if (currentMillis - previousMillis >= 200) {
        previousMillis = currentMillis;
        //updateBatteryLevel();
        while (Serial.available()) {
          char c = Serial.read();  //gets one byte from serial buffer
          readString += c; //makes the string readString
          delay(2);  //slow looping to allow buffer to fill with next character
        }
      
        if (readString.length() >0) {
          Serial.println(readString);  //so you can see the captured string 
          int batteryLevel = readString.toInt();  //convert readString into a number
          batteryLevelChar.setValue(batteryLevel);
          Serial.println("Battery Level Update\n");
          readString = "";
        }
      }
    }
    // when the central disconnects, turn off the LED:
    digitalWrite(13, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  }
}

void updateBatteryLevel() {
  /* Read the current voltage level on the A0 analog input pin.
     This is used here to simulate the charge level of a battery.
  */
  /*
  int battery = analogRead(A0);
  int batteryLevel = map(battery, 0, 1023, 0, 100);
  
  if (batteryLevel != oldBatteryLevel) {      // if the battery level has changed
    Serial.print("Battery Level % is now: "); // print it
    Serial.println(batteryLevel);
    batteryLevelChar.setValue(batteryLevel);  // and update the battery level characteristic
    oldBatteryLevel = batteryLevel;           // save the level for next comparison
  }
  */
}
