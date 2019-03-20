//
//  AppDelegate.h
//
//  Created by Guillermo Cubero on 11/28/17.
//  Copyright © 2017 Guillermo Cubero. All rights reserved.
//
//  Edited and Adapted by Andres Agauiza 1/1/18
//  Copyright © 2018 Andres Aguaiza. All rights reserved.

#import <UIKit/UIKit.h>
#import <StarIO_Extension/StarIoExt.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSString *)getPortName;

+ (void)setPortName:(NSString *)portName;

+ (NSString *)getPortSettings;

+ (void)setPortSettings:(NSString *)portSettings;

+ (NSString *)getModelName;

+ (void)setModelName:(NSString *)modelName;

//+ (NSString *)getMacAddress;

//+ (void)setMacAddress:(NSString *)macAddress;

+ (StarIoExtEmulation)getEmulation;

+ (void)setEmulation:(StarIoExtEmulation)emulation;

+ (BOOL)getCashDrawerOpenActiveHigh;

+ (void)setCashDrawerOpenActiveHigh:(BOOL)activeHigh;

@end

