//
//  ViewController.m
//  Bluetooth
//
//  Created by Marshal on 2020/4/17.
//  Copyright © 2020 Marshal. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *serviceUUID = @"11000000-0000-0000-0000-818282828282";
static NSString *characterUUID = @"12000000-0000-0000-0000-000000000000";
static NSString *writeCharacterUUID = @"13000000-0000-0000-0000-000000000000";

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    NSString *_uuidStr;
}

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;

@property (weak, nonatomic) IBOutlet UITextField *tfWifiName;
@property (weak, nonatomic) IBOutlet UITextField *tfPassword;
@property (weak, nonatomic) IBOutlet UITextField *tfOtherInfo;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (IBAction)connect:(id)sender {
    if (_tfWifiName.text.length < 1) {
        _tfWifiName.text = @"TP-LINK_haha";
    }
    if (_tfPassword.text.length < 1) {
        _tfPassword.text = @"lla_skdfasdf";
    }
    if (_tfOtherInfo.text.length < 1) {
        _tfOtherInfo.text = @"😄😄😄😄😄😄😄😄😄";
    }
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
            break;
        case CBManagerStatePoweredOn:{
            [_manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
            break;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"peripheral:%@, advertisementData: %@ ",peripheral,  advertisementData);
    if (!advertisementData) return;
    id localName = advertisementData[@"kCBAdvDataLocalName"];
    if (localName && [localName hasPrefix:@"DAKA_"]) {
        _uuidStr = [localName substringFromIndex:5];
        if (_uuidStr.length < 1 || _uuidStr.length > 12) return;
        _peripheral = peripheral;
        [central connectPeripheral:peripheral options:nil];
        [central stopScan];
        return;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    _peripheral.delegate = self;
    [_peripheral discoverServices:@[[CBUUID UUIDWithString:[serviceUUID stringByAppendingString:_uuidStr]]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (error) return;
    [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [peripheral discoverCharacteristics:nil forService:obj];
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.UUID.UUIDString isEqualToString:characterUUID]) {
            self.characteristic = (CBMutableCharacteristic *)obj;
            [peripheral setNotifyValue:YES forCharacteristic:self.characteristic]; //设置了通知对面更新数据则可以得到，成功了会回调notification，并且对面更新值也可以接收到，不然只能主动读取
//            [self.peripheral readValueForCharacteristic:self.characteristic]; //读取操作能主动读取，如果设置通知，广播方支持，则可以不读取
        }else if ([obj.UUID.UUIDString isEqualToString:writeCharacterUUID]) {
            self.writeCharacteristic = obj;
            [self.peripheral writeValue:[[NSString stringWithFormat:@"**%@//%@", _tfWifiName.text, _tfPassword.text] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didUpdateValueForCharacteristic:error:%@", error);
    NSLog(@"didUpdateValueForCharacteristic: %@ \n value:%@", characteristic, [NSString stringWithCString:characteristic.value.bytes encoding:NSUTF8StringEncoding]);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didWriteValueForCharacteristic:error:%@", error);
    NSLog(@"didWriteValueForCharacteristic: %@", characteristic);
    static int a = 0;
    if (a % 6 == 0) {
        [self.peripheral writeValue:[[NSString stringWithFormat:@"//%@**", _tfOtherInfo.text] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
    }
    a++;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic:error:%@", error);
    NSLog(@"didUpdateNotificationStateForCharacteristic: %@", characteristic);
}

@end
