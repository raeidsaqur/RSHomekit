//
//  HomeKitUtility.m
//  RSHomeKit
//
//  Created by Raeid Saqur on 2016-03-31.
//  Copyright © 2016 Raeid Saqur. All rights reserved.
//

#import "HomeKitUtility.h"

@implementation HomeKitUtility

static BOOL showFullDepthDescription = NO;
//static NSString *const kHomeKitEntitlementKeyIdentifier = @"com.yourentitlementkey.here";

/**
 * @discussion: Returns empty string if accessory is unreachable.
 *  Cannot fetch the actual serial number in unreachable state.
 */

+ (NSString *)getSerialNumberFromHMAccessory:(HMAccessory *)accessory {
    if (!accessory || !accessory.reachable) {
        return @"";
    }
    
    for (HMService *service in accessory.services) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", @"characteristicType", HMCharacteristicTypeSerialNumber];
        NSArray *result = [service.characteristics filteredArrayUsingPredicate:predicate];
        if (result && [result count] > 0 && [result[0] isKindOfClass:[HMCharacteristic class]]) {
            HMCharacteristic *serialNumChar = (HMCharacteristic *)result[0];
            NSString *serialNum = [serialNumChar valueForKey:@"value"];
            if (serialNum && [serialNum length] > 0) {
                return serialNum;
            }
        }
    }
    
    return @"";
}

+ (HMService *)getThermostatServiceForAccessory:(HMAccessory *)accessory {
    if (!accessory || !accessory.reachable || accessory.blocked) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", @"serviceType", HMServiceTypeThermostat];
    NSArray *result = [accessory.services filteredArrayUsingPredicate:predicate];
    if (result && [result count] > 0 && [result[0] isKindOfClass:[HMService class]]) {
        HMService *service = (HMService *)result[0];
        if (service) {
            return service;
        }
    }
    
    return nil;
}

+ (NSArray *)getFilteredCharacteristicsWithUUIDs:(NSArray *)uuids inThermostatService:(HMService *)tstatService {
    if (!tstatService || !uuids || (uuids.count == 0)) {
        return [NSArray array];
    }
    
    NSMutableArray *filteredCharacteristics = [NSMutableArray new];
    ;
    for (NSString *uuid in uuids) {
        HMCharacteristic *characteristic = [HomeKitUtility getCharacteristicWithUUID:uuid forHMService:tstatService];
        if (characteristic) {
            [filteredCharacteristics addObject:characteristic];
        }
    }
    return filteredCharacteristics;
}

+ (NSArray *)getFilteredCharacteristicsWithUUIDSet:(NSSet *)uuids inThermostatService:(HMService *)tstatService {
    if (!tstatService || !uuids) {
        return nil;
    }
    return [HomeKitUtility getFilteredCharacteristicsWithUUIDs:[uuids allObjects] inThermostatService:tstatService];
}

+ (HMCharacteristic *)getCharacteristicWithUUID:(NSString *)uuid forAccessory:(HMAccessory *)accessory {
    if (!accessory || !(uuid && [uuid length] > 0)) {
        return nil;
    }
    
    for (HMService *service in accessory.services) {
        HMCharacteristic *characteristic = [HomeKitUtility getCharacteristicWithUUID:uuid forHMService:service];
        if (characteristic) {
            return characteristic;
        }
    }
    return nil;
}

+ (HMCharacteristic *)getCharacteristicWithUUID:(NSString *)uuid forHMService:(HMService *)service {
    if (!service || !(uuid && [uuid length] > 0)) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", @"characteristicType", uuid];
    NSArray *result = [service.characteristics filteredArrayUsingPredicate:predicate];
    if (result && [result count] > 0 && [result[0] isKindOfClass:[HMCharacteristic class]]) {
        HMCharacteristic *characteristic = (HMCharacteristic *)result[0];
        if (characteristic) {
            return characteristic;
        }
    }
    return nil;
}

+ (HMService *)getThermostatServiceWithName:(NSString *)serviceName inHome:(HMHome *)home {
    if (!serviceName || !home) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", @"name", serviceName];
    NSArray *services = [home servicesWithTypes:@[ HMServiceTypeThermostat ]];
    NSArray *result = [services filteredArrayUsingPredicate:predicate];
    if (result && [result count] > 0 && [result[0] isKindOfClass:[HMService class]]) {
        HMService *service = (HMService *)result[0];
        if (service) {
            return service;
        }
    }
    return nil;
}

/*
 *@discussion: Uses thermostat service name to search for action sets created.
 */
+ (NSArray *)getAllActionSetsForAccessory:(HMAccessory *)accessory underHome:(HMHome *)home {
    if (!accessory || !home || !home.actionSets || [home.actionSets count] == 0) {
        return nil;
    }
    
    HMService *tService = [HomeKitUtility getThermostatServiceForAccessory:accessory];
    if (!tService || !tService.name) {
        return nil;
    }
    
    return [HomeKitUtility getAllActionSetsWithThermostatServiceName:tService.name underHome:home];
}

+ (NSArray *)getAllActionSetsWithThermostatServiceName:(NSString *)name underHome:(HMHome *)home {
    if (!name || !home || !home.actionSets) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH %@", @"name", name];
    NSArray *result = [home.actionSets filteredArrayUsingPredicate:predicate];
    if (result && [result count] > 0) {
        return result;
    }
    return nil;
}


/**
    This method juxtaposes the target temperature unit in a characteristic's meta data 
    and compares it with the target temperature characteristic's value.
    
    @return true if there's a mismatch
 */

+ (BOOL)isTemperatureDisplayUnitMismatch:(HMCharacteristic *)characteristic {
    if ([characteristic.characteristicType isEqualToString:HMCharacteristicTypeTargetTemperature]) {
        HMCharacteristic *tUnitCharacteristic = [HomeKitUtility getCharacteristicWithUUID:HMCharacteristicTypeTemperatureUnits
                                                                             forHMService:characteristic.service];
        NSString *targetTempUnits = characteristic.metadata.units;
        NSInteger valueInt = [tUnitCharacteristic.value integerValue];
        
        BOOL celciusMismatch = [targetTempUnits isEqualToString:HMCharacteristicMetadataUnitsCelsius] && valueInt != HMCharacteristicValueTemperatureUnitCelsius;
        BOOL fahrenheitMismatch = [targetTempUnits isEqualToString:HMCharacteristicMetadataUnitsFahrenheit] && valueInt != HMCharacteristicValueTemperatureUnitFahrenheit;
        
        return (celciusMismatch || fahrenheitMismatch);
    }
    
    return NO;
}


#pragma mark - Manufacturer Specific Helpers -

/**
 * @discussion: this utility method returns the manufacturer name associated with a HMCharacteristicWriteAction
 *
 * Note: the target service must be paired for this to work.
 * @return The value of Manufacturer characteristic in NSString format if associated accessory is paired and reachable.
 * @return null otherwise
 */
+ (NSString *)getManufacturerNameForHMAction:(HMCharacteristicWriteAction *)action {
    if (!action || !action.characteristic || !action.characteristic.service) {
        return nil;
    }
    
    HMAccessory *accessory = action.characteristic.service.accessory;
    if (accessory) {
        return [HomeKitUtility getManufacturerNameForHMAccessory:accessory];
    }
    
    return nil;
}

/**
 * @discussion: If accessory is unreachable, it will find the characteristic, however, the value will be null.
 */

+ (NSString *)getManufacturerNameForHMAccessory:(HMAccessory *)accessory {
    if (!accessory) {
        return nil;
    }
    HMCharacteristic *manufacturer = [HomeKitUtility getCharacteristicWithUUID:HMCharacteristicTypeManufacturer forAccessory:accessory];
    
    if (manufacturer && manufacturer.value) {
        return (NSString *)manufacturer.value;
    }
    return nil;
}

+ (BOOL)doesAccessory:(HMAccessory *)accessory matchManufacturerName:(NSString *)manufacturerName {
    
    if (!accessory) { return NO; }
    NSString *mName = [HomeKitUtility getManufacturerNameForHMAccessory:accessory];
    if (mName && [mName isEqualToString:manufacturerName]) {
        return YES;
    }
    return NO;
}

/***
    Gets the count of all HMAccessories by Manufacturer name. 
 
    @param home 
    @param manufacturerName
    @return count of accessories by manufacturer - will be <= total accessories count
 */
+ (NSUInteger)getCountOfAccessoriesUnderHome:(HMHome *)home withManufacturerName:(NSString *)manufacturerName {
    if (!home || !home.accessories || ([home.accessories count] < 1)) {
        return 0;
    }

    NSArray<HMAccessory *> *filteredAccessories = [home.accessories filteredArrayUsingPredicate:([NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
        return [HomeKitUtility doesAccessory:obj matchManufacturerName:manufacturerName];
        
    }])];
    
    return [filteredAccessories count];
}

+ (NSArray <HMAccessory *> *)getAllAccessoriesUnderHome:(HMHome *)home withManufacturerName:(NSString *)manufacturerName {
    if (!home || !home.accessories || ([home.accessories count] < 1)) {
        return nil;
    }
    NSArray<HMAccessory *> *filteredAccessories = [home.accessories filteredArrayUsingPredicate:([NSPredicate predicateWithBlock:^BOOL(id acc, NSDictionary *bindings) {
        return [HomeKitUtility doesAccessory:acc matchManufacturerName:manufacturerName];
    }])];
    
    if (filteredAccessories && [filteredAccessories count] > 0) {
        return filteredAccessories;
    } else {
        return nil;
    }
}

#pragma mark - Debug Helpers -
+ (NSString *)detailedDescriptionOfHMAccessory:(HMAccessory *)accessory {
    if (!accessory) {
        return @"";
    }
    
    NSString *descriptionString = [NSString stringWithFormat:@"\n\n###################### START ######################\n\t\t\t\tHMAccessory: %@\n", accessory.name];
    if (showFullDepthDescription) {
        NSArray *services = accessory.services;
        for (HMService *service in services) {
            descriptionString = [descriptionString stringByAppendingString:[self detailedDescriptionOfHMService:service]];
        }
    }
    
    return [descriptionString stringByAppendingString:@"\n###################### END ########################\n\n"];
}

+ (NSString *)detailedDescriptionOfHMService:(HMService *)service;
{
    if (!service) {
        return @"";
    }
    
    NSString *descriptionString = [NSString stringWithFormat:@"\n\t################## HMService: %@ ##################\n", service.name];
    NSArray *characteristics = service.characteristics;
    for (HMCharacteristic *chr in characteristics) {
        descriptionString = [descriptionString stringByAppendingString:[self detailedDescriptionOfHMCharacteristic:chr]];
    }
    
    return descriptionString;
}

+ (NSString *)detailedDescriptionOfHMCharacteristic:(HMCharacteristic *)chr {
    if (!chr) {
        return @"";
    }
    
    NSString *descriptionString = [NSString stringWithFormat:@"\n\t\t############## HMCharacteristic - Type: %@, Value: %@ ##############\n",
                                   chr.characteristicType, chr.value];
    
    return descriptionString;
}

+ (NSString *)detailedDescriptionOfHMHome:(HMHome *)home {
    if (!home) {
        return @"";
    }
    
    NSString *descriptionString = [NSString stringWithFormat:@"\n###################### HMHome: %@ ######################\n", home.name];
    for (HMRoom *room in home.rooms) {
        descriptionString = [descriptionString stringByAppendingString:[self detailedDescriptionOfHMRoom:room]];
    }
    
    return descriptionString;
}

+ (NSString *)detailedDescriptionOfHMRoom:(HMRoom *)room {
    if (!room) {
        return @"";
    }
    
    NSString *descriptionString = [NSString stringWithFormat:@"\n###################### HMRoom: %@ ######################\n", room.name];
    for (HMAccessory *acc in room.accessories) {
        descriptionString = [descriptionString stringByAppendingString:[self detailedDescriptionOfHMAccessory:acc]];
    }
    
    return descriptionString;
}


#pragma mark - Non-HomeKit Helpers -
+ (void)openSettings {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:url];
}

+ (NSString *)convertDataToString:(NSData *)data {
    if (data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return string;
    }
    return nil;
}

@end
