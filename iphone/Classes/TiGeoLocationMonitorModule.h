/**
 * Ti.Geo.LocationMonitor
 *
 * Created by Ben Bahrenburg
 * Copyright (c) 2015 bencoding.com, All rights reserved.
 */

#import "TiModule.h"
#import <CoreLocation/CoreLocation.h>

@interface TiGeoLocationMonitorModule : TiModule<CLLocationManagerDelegate> 
{
@private
    float _staleLimit;
    NSTimer* locationTimeoutTimer;
    CLActivityType activityType;
    BOOL pauseLocationUpdateAutomatically;
}

@end
