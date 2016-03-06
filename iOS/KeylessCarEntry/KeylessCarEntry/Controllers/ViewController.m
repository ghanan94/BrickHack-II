//
//  ViewController.m
//  KeylessCarEntry
//
//  Created by Ghanan Gowripalan on 2016-03-05.
//  Copyright © 2016 Surfin' Sandshrew. All rights reserved.
//

#define DEVICE_INFORMATION_SERVICE_UUID @"180A"
#define KEYLESS_ENTRY_SERVICE_UUID @"CADE0000-F78F-4F65-846A-C4DC27285BA3"

#define KEYLESS_ENTRY_DEVICE_KEY_CHARACTERISTIC_UUID @"CADE0001-F78F-4F65-846A-C4DC27285BA3"
#define KEYLESS_ENTRY_STATUS_CODE_CHARACTERISTIC_UUID @"CADE0002-F78F-4F65-846A-C4DC27285BA3"

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.keyPeripheral = nil;
    
    // Init the central manager
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager = centralManager;
    
    //reset buffer for rssi values
    rssi_buffer tmp;
    tmp.contents[0] = tmp.contents[1] = tmp.contents[2] = 0;
    self.rssi_values = tmp;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    [self.connectedLabel setText:self.connected];
    NSLog(@"%@", self.connected);
}

// method called whenever you have disconnected from the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"Disconnected from peripheral");
    
    self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    [self.connectedLabel setText:self.connected];
    [self.statusLabel setText:@"Out of range"];
    [self.centralManager cancelPeripheralConnection:self.keyPeripheral];
    self.keyPeripheral = nil;
    
    // Scan for all available CoreBluetooth LE devices again
    NSArray *services = @[[CBUUID UUIDWithString:KEYLESS_ENTRY_SERVICE_UUID]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber  numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [central scanForPeripheralsWithServices:services options:options];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"DidFailToConnectPeripheral");
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    //NSLog(@"didDiscoverPeripheral: %@", [NSString stringWithFormat:@"%@", [advertisementData description]]);
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"%@", localName);
    
    //[self.statusLabel setText:[NSString stringWithFormat:@"%s", "Waiting for data"]];
    
    rssi_buffer tmp = self.rssi_values;
    tmp.contents[0] = tmp.contents[1];
    tmp.contents[1] = tmp.contents[2];
    tmp.contents[2] = RSSI.intValue;
    self.rssi_values = tmp; //push most recent rssi onto buffer and set
    BOOL validData = true;
    
    if (tmp.contents[0] > -20 || tmp.contents[1] > -20 ||  tmp.contents[2] > -20){
        validData = false;
        NSLog(@"Current data is %s", "false");
    } else {
        NSLog(@"Current data is %s", "true");
    }
    
    if ([localName length] > 0 && validData == true) {
        double avgRssi = tmp.contents[0] + tmp.contents[1] + tmp.contents[2];
        avgRssi = avgRssi / 3;
        NSLog(@"Current average rssi is: %f", avgRssi);
        //[self.statusLabel setText:[NSString stringWithFormat:@"%f", avgRssi]];
        
        if (avgRssi > -65){
            NSLog(@"Found the key peripheral: %@", localName);
            [self.centralManager stopScan];
            self.keyPeripheral = peripheral;
            peripheral.delegate = self;
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
    } else{
        //[self.statusLabel setText:[NSString stringWithFormat:@"%s", "Not enough valid data"]];
    }
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // Determine the state of the peripheral (ios device should be i think)
    self.connected = @"Connected: NO";
    [self.connectedLabel setText:self.connected];
    [self.statusLabel setText:@"Out of range"];
    if (self.keyPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.keyPeripheral];
    }
    self.keyPeripheral = nil;
    
    
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        
        // Scan for all available CoreBluetooth LE devices
        NSArray *services = @[[CBUUID UUIDWithString:KEYLESS_ENTRY_SERVICE_UUID]];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber  numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        [central scanForPeripheralsWithServices:services options:options];
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}

#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // Retrieve Device Information Services for the Manufacturer Name
    NSLog(@"Service: %@", service.UUID);
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:KEYLESS_ENTRY_SERVICE_UUID]])  {
        for (CBCharacteristic *aChar in service.characteristics) {
            NSLog(@"Characteristic: %@", [aChar UUID]);
            
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:KEYLESS_ENTRY_DEVICE_KEY_CHARACTERISTIC_UUID]]) {
                self.keylessEntryDeviceKeyCharacteristic = aChar;
                NSLog(@"Found a keyless entry device key characteristic");
                
                NSString *key = @"San";
                unsigned char charString[[key length]];
                
                for (int i = 0; i < [key length]; ++i) {
                    charString[i] = (unsigned char)[key characterAtIndex:i];
                }
                
                NSData *data = [NSData dataWithBytes:charString length:[key length]];
                [self.keyPeripheral writeValue:data forCharacteristic:self.keylessEntryDeviceKeyCharacteristic type:CBCharacteristicWriteWithResponse];
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:KEYLESS_ENTRY_STATUS_CODE_CHARACTERISTIC_UUID]]) {
                [self.keyPeripheral readValueForCharacteristic:aChar];
                [self.keyPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a keyless entry status code characteristic");
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state %@: %@", [characteristic UUID], error);
        return;
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // Updated value for battery level received
    NSLog(@"Charactersiic uuid: %@", characteristic.UUID);
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:KEYLESS_ENTRY_STATUS_CODE_CHARACTERISTIC_UUID]]) { // 1
        NSData *data = [characteristic value];

        NSString *statusText;
        const uint8_t *bytes = [data bytes];
        int statusCode = bytes[0];
        
        switch (statusCode) {
            case KeylessEntryStatusCodeOkay:
                statusText = @"Okay";
                break;
            
            case KeylessEntryStatusCodeError:
            default:
                statusText = @"Error";
                break;
        }

        [self.statusLabel setText:statusText];
        NSLog(@"Keyless Entry Status: %@", statusText);
    }
}

- (IBAction)testButtonPressed:(id)sender {
    NSString *key = @"San";
    unsigned char charString[[key length]];
    
    for (int i = 0; i < [key length]; ++i) {
        charString[i] = (unsigned char)[key characterAtIndex:i];
    }

    NSData *data = [NSData dataWithBytes:charString length:[key length]];
    [self.keyPeripheral writeValue:data forCharacteristic:self.keylessEntryDeviceKeyCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error writing characteristic value: %@", error);
    }
}


@end
