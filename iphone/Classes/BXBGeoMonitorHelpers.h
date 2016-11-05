/**
 * Ti.Geo.LocationMonitor
 *
 * Created by Ben Bahrenburg
 * Copyright (c) 2015 bencoding.com, All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "TiUtils.h"

@interface BXBGeoMonitorHelpers : NSObject
- (void) disabledLocationServiceMessage;
- (NSDictionary*)buildFromPlaceLocation:(CLPlacemark *)placemark;
- (NSDictionary*)locationDictionary:(CLLocation*)newLocation;
@end
