//
//  ViewController.m
//  MinBleDemo
//
//  Created by apple on 16/3/21.
//  Copyright © 2016年 lny. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SecondViewController.h"
#import "MBProgressHUD+MJ.h"

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic ,strong)CBCentralManager *bleManager;
@property (weak, nonatomic) IBOutlet UITableView *tabView;

@property (nonatomic ,strong)NSMutableArray *uuids;
@property (nonatomic ,strong)NSMutableArray *peripherals;
@property (nonatomic ,strong)NSMutableArray *services;
@property (nonatomic ,strong)NSMutableArray *characters;
@property (nonatomic ,strong)NSMutableArray *rssis;

@property (nonatomic ,strong)CBPeripheralManager *perManager;


@end

@implementation ViewController

- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (NSMutableArray *)uuids{
    if (!_uuids) {
        _uuids = [NSMutableArray array];
    }
    return _uuids;
}

- (NSMutableArray *)services{
    if (!_services) {
        _services = [NSMutableArray array];
    }
    return _services;
}
- (NSMutableArray *)characters{
    if (!_characters) {
        _characters =[NSMutableArray array];
    }
    return _characters;
}

- (NSMutableArray *)rssis{
    if (!_rssis) {
        _rssis = [NSMutableArray array];
    }
    return _rssis;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.bleManager = [[CBCentralManager alloc]init];
    self.bleManager.delegate = self;
    
//    [self.bleManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    NSLog(@"%@",self.peripherals);
    return self.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *iden = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:iden];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:iden];
    }
    CBPeripheral *peripheral = self.peripherals[indexPath.row];
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text =  [NSString stringWithFormat:@"%ld",(long)[peripheral state]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    [self.bleManager stopScan];
//    SecondViewController *secVC = [SecondViewController new];
//    
//    
    CBPeripheral *peripheral = self.peripherals[indexPath.row];
    //连接外设
    [self.bleManager connectPeripheral:peripheral options:nil];
//    secVC.peripheral = peripheral;
}


#pragma mark CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSLog(@"centralManagerDidUpdateState");
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙已打开,请扫描外设");
        [MBProgressHUD showError:@"蓝牙已打开,请扫描外设"];
        [self.bleManager scanForPeripheralsWithServices:nil options:nil];
    }else if(central.state == CBCentralManagerStatePoweredOff){
        [MBProgressHUD showError:@"蓝牙没有打开,请先打开蓝牙"];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    if (![self.peripherals containsObject:peripheral] &&peripheral.name.length > 0) {
        //AM-MPU605Bf  Beacon
        if ([peripheral.name isEqualToString:@"Beac"]||[peripheral.name isEqualToString:@"BeacoC"]||[peripheral.name hasPrefix:@"AM"]) {
        
            peripheral.delegate = self;
            
            NSLog(@"已扫描到的peripheral:%@,--advertisementData:%@,--RSSI:%@",peripheral,advertisementData,RSSI);
            [self.peripherals addObject:peripheral];
            [self.rssis addObject:RSSI];
            [self.bleManager connectPeripheral:peripheral options:nil];
        }
    }
    
    
//    if (![self.peripherals containsObject:peripheral] && peripheral.name.length > 0) {
//        peripheral.delegate = self;
//        
//        NSLog(@"已扫描到的peripheral:%@,--advertisementData:%@,--RSSI:%@",peripheral,advertisementData,RSSI);
//        [self.peripherals addObject:peripheral];
//        [self.rssis addObject:RSSI];
//        [self.bleManager connectPeripheral:peripheral options:nil];
//    }
    [self.tabView reloadData];
    
}

//连接外设成功调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
//    NSLog(@"didConnectPeripheral");
    [peripheral  discoverServices:nil];
    NSLog(@"连接外设成功,开始发现服务");
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSLog(@"didFailToConnectPeripheral");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self.bleManager connectPeripheral:peripheral options:nil];
}

#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"didDiscoverServices");
    
    NSArray *services = peripheral.services;
    
    for (CBService *ser in services) {
        if (![self.services containsObject:ser]) {
            [self.services addObject:ser];
        }
    }

    
//    NSLog(@"services---%@",services);
    
    for (CBService *s in services) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [peripheral discoverCharacteristics:nil forService:s];
        });
        
    }
}
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    
    NSLog(@"peripheralDidUpdateName%@",peripheral);
}

//- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
//    if (!error) {
//        NSLog(@"rssi %d",[[peripheral RSSI] integerValue]);
//    }
//}

//已搜索到Characteristics
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"%@",[NSString stringWithFormat:@"发现特征的服务:%@ (%@)",service.UUID.data ,service.UUID]);
    
    for (CBCharacteristic *c in service.characteristics) {
        NSLog(@"%@",[NSString stringWithFormat:@"特征 UUID: %@ (%@)",c.UUID.data,c.UUID]);
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]]) {
            [peripheral readValueForCharacteristic:c];
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]]) {
            [peripheral readValueForCharacteristic:c];
//            [peripheral setNotifyValue:YES forCharacteristic:c];
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF3"]]) {
//            [peripheral readRSSI];
            [peripheral readValueForCharacteristic:c];
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF4"]]) {
//            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF5"]]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
        }
        
        
//        [peripheral readValueForCharacteristic:c];
//        [peripheral setNotifyValue:YES forCharacteristic:c];

        [self.characters addObject:c];
    }
}



//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [NSThread sleepForTimeInterval:1];
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]]) {
    NSData * data = characteristic.value;
    Byte * resultByte = (Byte *)[data bytes];
    NSLog(@"resultByte----%s",resultByte);
    for(int i=0;i<[data length];i++)
//        if(i == 4){
            printf("testByteFFF1[%d] = %d\n",i,resultByte[i]);
//        }
        
    
    switch (resultByte[0]) {
        case 1:
        {
            
        }
        case 2:
        {
            
        }
            
            break;
        default:
            break;
    }
}
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]]) {
        NSData * data = characteristic.value;
        Byte * resultByte = (Byte *)[data bytes];
      NSLog(@"%s",resultByte);
        for(int i=0;i<[data length];i++)
            
            printf("testByteFFF2[%d] = %d\n",i,resultByte[i]);
        
        switch (resultByte[0]) {
            case 1:
            {
//
            }
            case 2:
            {

            }
            
                break;
            default:
                break;
        }
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFF3"]]) {
        NSData * data = characteristic.value;
        Byte * resultByte = (Byte *)[data bytes];
        NSLog(@"%s",resultByte);
        for(int i=0;i<[data length];i++)
            printf("testByteFFF3[%d] = %d\n",i,resultByte[i]);
        
        switch (resultByte[0]) {
            case 1:
            {
                
            }
            case 2:
            {
                
            }
                
                break;
            default:
                break;
        }
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFF4"]]&&characteristic.isNotifying) {
        NSData * data = characteristic.value;
        NSLog(@"data----%@",data);
        Byte * resultByte = (Byte *)[data bytes];
        
        for(int i=0;i<[data length];i++)
            printf("testByteFFF4[%d] = %d\n",i,resultByte[i]);
        
    }
    

}



//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        NSLog(@"%@",[NSString stringWithFormat:@"Notification stopped on %@.  Disconnecting", characteristic]);
//        [self.bleManager cancelPeripheralConnection:peripheral];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.bleManager connectPeripheral:peripheral options:nil];
        });
    }
}

//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"=======%@",error.userInfo);


    }else{
        NSLog(@"发送数据成功");

    }
    
    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
    [peripheral readValueForCharacteristic:characteristic];
}


@end
