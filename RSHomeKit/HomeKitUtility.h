//
//  HomeKitUtility.h
//  RSHomeKit
//
//  Created by Raeid Saqur on 2016-03-31.
//  Copyright © 2016 Raeid Saqur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HomeKit/HomeKit.h>
#import <UIKit/UIKit.h>


@interface HomeKitUtility : NSObject

+ (NSString *)getSerialNumberFromHMAccessory:(HMAccessory *)accessory;

+ (HMService *)getThermostatServiceForAccessory:(HMAccessory *)accessory;

+ (NSArray *)getFilteredCharacteristicsWithUUIDs:(NSArray *)uuids inThermostatService:(HMService *)tstatService;

+ (NSArray *)getFilteredCharacteristicsWithUUIDSet:(NSSet *)uuids inThermostatService:(HMService *)tstatService;

+ (HMCharacteristic *)getCharacteristicWithUUID:(NSString *)uuid forAccessory:(HMAccessory *)accessory;

+ (HMCharacteristic *)getCharacteristicWithUUID:(NSString *)uuid forHMService:(HMService *)service;

+ (HMService *)getThermostatServiceWithName:(NSString *)serviceName inHome:(HMHome *)home;

+ (NSArray *)getAllActionSetsForAccessory:(HMAccessory *)accessory underHome:(HMHome *)home;

+ (NSArray *)getAllActionSetsWithThermostatServiceName:(NSString *)name underHome:(HMHome *)home;

+ (BOOL)isTemperatureDisplayUnitMismatch:(HMCharacteristic *)characteristic;


+ (NSString *)getManufacturerNameForHMAction:(HMAction *)action;

+ (NSString *)getManufacturerNameForHMAccessory:(HMAccessory *)accessory;

+ (BOOL)doesAccessory:(HMAccessory *)accessory matchManufacturerName:(NSString *)manufacturerName;

+ (NSUInteger)getCountOfAccessoriesUnderHome:(HMHome *)home withManufacturerName:(NSString *)manufacturerName;

+ (NSArray <HMAccessory *> *)getAllAccessoriesUnderHome:(HMHome *)home withManufacturerName:(NSString *)manufacturerName;


+ (NSString *)detailedDescriptionOfHMAccessory:(HMAccessory *)accessory;

+ (NSString *)detailedDescriptionOfHMService:(HMService *)service;

+ (NSString *)detailedDescriptionOfHMCharacteristic:(HMCharacteristic *)chr;

+ (NSString *)detailedDescriptionOfHMHome:(HMHome *)home;

+ (NSString *)detailedDescriptionOfHMRoom:(HMRoom *)room;


+ (void)openSettings;

+ (NSString *)convertDataToString:(NSData *)data;

+ (NSArray <HMService *> *)getFilteredServicesUnderHome:(HMHome *)home
                                         ofServiceTypes:(NSArray<NSString *>  *)serviceTypes
                                     byManufacturerName:(NSString *)manufacturer;

@end
