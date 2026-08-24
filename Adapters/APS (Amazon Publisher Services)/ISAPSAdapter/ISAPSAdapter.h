//
//  ISAPSAdapter.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>
#import <IronSource/ISSetAPSDataProtocol.h>

static NSString * const APSAdapterVersion = @"5.9.0";
static NSString * Githash = @"";

// System Frameworks For APS Adapter
@import CoreLocation;
@import CoreTelephony;
@import MediaPlayer;
@import StoreKit;
@import SystemConfiguration;
@import QuartzCore;

@interface ISAPSAdapter : LevelPlayBaseAdapter

@end
