//
//  ViewController.h
//  KeylessCarEntry
//
//  Created by Ghanan Gowripalan on 2016-03-05.
//  Copyright © 2016 Surfin' Sandshrew. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreBluetooth;
@import QuartzCore;

static NSString * const uartServiceUUIDString = @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString * const uartTXCharacteristicUUIDString = @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString * const uartRXCharacteristicUUIDString = @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

typedef NS_OPTIONS(NSUInteger, KeylessEntryStatusCodes) {
    KeylessEntryStatusCodeOkay = 0x00,
    KeylessEntryStatusCodeError = 0xff
};

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UILabel *connectedLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UIButton *testButton;


@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral     *keyPeripheral;

// Properties to hold data characteristics for the peripheral device
@property (nonatomic, strong) NSString   *connected;
//@property (nonatomic, strong) NSString   *bodyData;
//@property (nonatomic, strong) NSString   *manufacturer;
//@property (nonatomic, strong) NSString   *keyDeviceData;

@property (nonatomic, strong) CBCharacteristic *testCharacteristic;

// Instance methods to grab device Manufacturer Name, Body Location
//- (void) getManufacturerName:(CBCharacteristic *)characteristic;
//- (void) getBodyLocation:(CBCharacteristic *)characteristic;

- (IBAction)testButtonPressed:(id)sender;

@end

