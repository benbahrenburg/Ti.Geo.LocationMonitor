/**
 * Ti.Geo.LocationMonitor
 *
 * Created by Ben Bahrenburg
 * Copyright (c) 2015 bencoding.com, All rights reserved.
 */

#import "TiGeoLocationMonitorModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "BXBGeoMonitorHelpers.h"

@implementation TiGeoLocationMonitorModule

CLLocationManager * _locationManager;
int _Counter = 0;

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"7c43cb49-413e-4240-bb4e-207c3e044a86";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"Ti.Geo.LocationMonitor";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];

    locationTimeoutTimer = nil;
    
    // activity Type by default
    activityType = CLActivityTypeOther;
    
    // pauseLocationupdateAutomatically by default NO
    pauseLocationUpdateAutomatically  = NO;

}

-(void)shutdown:(id)sender
{
    [self shutdownLocationManager];

	// you *must* call the superclass
	[super shutdown:sender];
    
}

#pragma mark Cleanup


#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

-(void)locationChangedEvent:(CLLocation*)location
{
    
    if([self _hasListeners:@"change"]){
        //Determine of the data is stale
        NSDate* eventDate = location.timestamp;
        NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
        
        BXBGeoMonitorHelpers * helpers = [[BXBGeoMonitorHelpers alloc] init];
        NSDictionary *todict = [helpers locationDictionary:location];
        
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               todict,@"coords",
                               NUMBOOL(YES),@"success",
                               NUMBOOL((fabs(howRecent) < _staleLimit)),@"stale",
                               nil];
        [self fireEvent:@"change" withObject:event];
    }
    
}
-(NSDictionary*)locationToDict:(CLLocation*)location
{
    BXBGeoMonitorHelpers * helpers = [[BXBGeoMonitorHelpers alloc] init];
    return [helpers locationDictionary:location];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if([self _hasListeners:@"error"])
    {
        NSDictionary *errEvent = [NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription],@"error",
                                  NUMINT((int)[error code]), @"code",
                                  NUMBOOL(NO),@"success",nil];
        
        [self fireEvent:@"error" withObject:errEvent];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //NSLog(@"didUpdateToLocation");
    [self locationChangedEvent : newLocation];
    
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //NSLog(@"didUpdateToLocations");
    CLLocation *location = [locations lastObject];
    [self locationChangedEvent : location];
}

-(void)shutdownLocationManager
{
    if (_locationManager!=nil){
        [_locationManager stopUpdatingHeading];
        _locationManager = nil;
    }
    
    if(locationTimeoutTimer!=nil){
        [locationTimeoutTimer invalidate];
        locationTimeoutTimer = nil;
    }
}
-(CLLocationManager*)tempLocationManager
{
    if (_locationManager!=nil)
    {
        // if we have an instance, just use it
        return _locationManager;
    }
    
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.pausesLocationUpdatesAutomatically = pauseLocationUpdateAutomatically;
        if([TiUtils isIOS9OrGreater]){
#if IS_XCODE_7
            _locationManager.allowsBackgroundLocationUpdates = YES;
#endif
        }
        [_locationManager setActivityType:NUMINT(activityType)];
    }
    return _locationManager;
}

- (void) triggerListner:(NSString *)name withEvents:(NSDictionary *)events
{
    if ([self _hasListeners:name])
    {
        [self fireEvent:name withObject:events];
    }
}

- (void)timerElapsed
{
    if(_Counter > 30000){
        _Counter = 0;
    }
    _Counter += 1;
    NSDictionary *timerEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"timerFired",@"action",
                                NUMINT(_Counter), @"intervalCount",
                                NUMBOOL(YES),@"success",nil];
    
    [self triggerListner:@"timerFired" withEvents:timerEvent];
}

- (void) startMonitoring:(id)args
{
    //We need to be on the UI thread, or the Change event wont fire
    ENSURE_UI_THREAD(startMonitoring,args);
    
    // pauseLocationupdateAutomatically by default NO
    pauseLocationUpdateAutomatically  = NO;
    
    BXBGeoMonitorHelpers * helpers = [[BXBGeoMonitorHelpers alloc] init];
    
    if ([CLLocationManager locationServicesEnabled]== NO)
    {
        [helpers disabledLocationServiceMessage];
        return;
    }
    
    float timerInterval = [TiUtils floatValue:[self valueForUndefinedKey:@"timerInterval"]def:-1];
    _staleLimit = [TiUtils floatValue:[self valueForUndefinedKey:@"staleLimit"]def:15.0];
    
    if(locationTimeoutTimer!=nil){
        [locationTimeoutTimer invalidate];
        locationTimeoutTimer = nil;
    }
    
    
    [[self tempLocationManager] startUpdatingLocation];
    
    NSDictionary *startEvent = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES),@"success",nil];
    
    if ([self _hasListeners:@"start"])
    {
        [self fireEvent:@"start" withObject:startEvent];
    }
    
    _Counter = 0; // Reset count
    if(timerInterval > 1){
        locationTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:
                                [[NSNumber numberWithFloat:timerInterval] doubleValue]
                                                                target:self
                                                              selector:@selector(timerElapsed)
                                                              userInfo:nil
                                                               repeats:YES];
    }
    
}

- (void) stopMonitoring:(id)args
{
    ENSURE_UI_THREAD(stopMonitoring,args);
    
    [self shutdownLocationManager];
    
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                           NUMBOOL(YES),@"success",nil];
    
    if ([self _hasListeners:@"stop"])
    {
        [self fireEvent:@"stop" withObject:event];
    }
    
    _Counter = 0; // Reset count
}

-(NSNumber*)pauseLocationUpdateAutomatically
{
    return NUMBOOL(pauseLocationUpdateAutomatically);
}

-(void)setPauseLocationUpdateAutomatically:(id)value
{
    ENSURE_UI_THREAD(setPauseLocationUpdateAutomatically,value);
    pauseLocationUpdateAutomatically = [TiUtils boolValue:value];
    [[self tempLocationManager] setPausesLocationUpdatesAutomatically:pauseLocationUpdateAutomatically];
}

-(NSNumber*)activityType
{
    return NUMINT(activityType);
}

-(void)setDistanceFilter:(NSNumber *)value
{
    ENSURE_UI_THREAD(setDistanceFilter,value);
    // don't prematurely start it
    if ([self tempLocationManager]!=nil)
    {
        [[self tempLocationManager] setDistanceFilter:[TiUtils doubleValue:value]];
    }
}
-(void)setAccuracy:(NSNumber *)value
{
    ENSURE_UI_THREAD(setAccuracy,value);
    // don't prematurely start it
    if ([self tempLocationManager]!=nil)
    {
        [[self tempLocationManager] setDesiredAccuracy:[TiUtils doubleValue:value]];
    }
}
-(void)setActivityType:(NSNumber *)value
{
    ENSURE_UI_THREAD(setActivityType,value);
    activityType = [TiUtils intValue:value];
    [[self tempLocationManager] setActivityType:NUMINT(activityType)];
    
}


@end
