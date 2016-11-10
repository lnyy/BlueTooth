//
//  SecondViewController.h
//  MinBleDemo
//
//  Created by apple on 16/3/23.
//  Copyright © 2016年 lny. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface SecondViewController : UIViewController

@property (nonatomic ,strong)CBPeripheral *peripheral;

@end
