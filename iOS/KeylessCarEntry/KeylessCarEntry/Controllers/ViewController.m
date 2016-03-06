//
//  ViewController.m
//  KeylessCarEntry
//
//  Created by Ghanan Gowripalan on 2016-03-05.
//  Copyright © 2016 Surfin' Sandshrew. All rights reserved.
//

#define KEY_DEVICE_INFORMATION_SERVICE_UUID @"180A"
#define KEY_OBJECT_TRANSFER_SERVICE_UUID @"1825"
#define KEY_BATTERY_SERVICE_UUID @"180F"

#define KEY_BATTERY_LEVEL_CHARACTERISTIC_UUID @"2A19"
#define KEY_HEART_RATE_MEASUREMENT_CHARACTERISTIC_UUID @"2A37"

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
    [self.centralManager cancelPeripheralConnection:self.keyPeripheral];
    self.keyPeripheral = nil;
    
    // Scan for all available CoreBluetooth LE devices again
    NSArray *services = @[[CBUUID UUIDWithString:KEY_DEVICE_INFORMATION_SERVICE_UUID]];
    [central scanForPeripheralsWithServices:services options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"DidFailToConnectPeripheral");
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    //NSLog(@"didDiscoverPeripheral: %@", [NSString stringWithFormat:@"%@", [advertisementData description]]);
    
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    
    if ([localName length] > 0 && [localName isEqualToString:@"Sandshrew"]) {
        NSLog(@"Found the key peripheral: %@", localName);
        [self.centralManager stopScan];
        self.keyPeripheral = peripheral;
        peripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // Determine the state of the peripheral (ios device should be i think)
    self.connected = @"Connected: NO";
    [self.connectedLabel setText:self.connected];
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
        NSArray *services = @[[CBUUID UUIDWithString:KEY_DEVICE_INFORMATION_SERVICE_UUID]];
        [central scanForPeripheralsWithServices:services options:nil];
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
    
    //if ([service.UUID isEqual:[CBUUID UUIDWithString:KEY_BATTERY_SERVICE_UUID]])  { // 4
        for (CBCharacteristic *aChar in service.characteristics)
        {
            NSLog(@"Characteristic: %@", [aChar UUID]);
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:KEY_BATTERY_LEVEL_CHARACTERISTIC_UUID]]) {
                //[self.keyPeripheral readValueForCharacteristic:aChar];
                [self.keyPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a Battery Level characteristic");
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:KEY_HEART_RATE_MEASUREMENT_CHARACTERISTIC_UUID]]) {
                self.testCharacteristic = aChar;
                NSLog(@"Found a HR measurement characteristic");
            }
        }
    //}
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
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:KEY_BATTERY_LEVEL_CHARACTERISTIC_UUID]]) { // 1
        // Get the battery level
        NSData *data = [characteristic value];
        [self.testLabel setText:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        [peripheral writeValue:data forCharacteristic:self.testCharacteristic type:CBCharacteristicWriteWithoutResponse];
        //NSLog(@"Sent Battery Level Data: %@, to peripheral", data);
        NSLog(@"Battery Level Data: %@", data);
    }
}

- (IBAction)testButtonPressed:(id)sender {
    NSData* data = (NSData *)@39;
    CBMutableCharacteristic *interestingChar = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:KEY_BATTERY_LEVEL_CHARACTERISTIC_UUID] properties:nil value:data permissions:(CBAttributePermissionsReadable | CBAttributePermissionsWriteable)];
    //[self.keyPeripheral writeValue:data forCharacteristic:interestingChar type:CBCharacteristicWriteWithoutResponse];
    
    [self.keyPeripheral readValueForCharacteristic:self.testCharacteristic];
    [self.keyPeripheral writeValue:data forCharacteristic:self.testCharacteristic type:CBCharacteristicWriteWithoutResponse];
    [self.keyPeripheral readValueForCharacteristic:self.testCharacteristic];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error writing characteristic value: %@", error);
    }
}


@end
