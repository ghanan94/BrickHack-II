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

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral     *keyPeripheral;

// Properties to hold data characteristics for the peripheral device
@property (nonatomic, strong) NSString   *connected;
//@property (nonatomic, strong) NSString   *bodyData;
//@property (nonatomic, strong) NSString   *manufacturer;
//@property (nonatomic, strong) NSString   *keyDeviceData;

// Instance methods to grab device Manufacturer Name, Body Location
//- (void) getManufacturerName:(CBCharacteristic *)characteristic;
//- (void) getBodyLocation:(CBCharacteristic *)characteristic;

@end

