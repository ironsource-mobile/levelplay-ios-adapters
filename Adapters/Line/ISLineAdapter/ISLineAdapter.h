//
//  ISLineAdapter.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const LineAdapterVersion = @"5.6.0";
static NSString * Githash = @"";

//System Frameworks For LineAdapter
@import AdSupport;
@import AVFoundation;
@import AppTrackingTransparency;
@import AudioToolbox;
@import CoreMedia;
@import CoreTelephony;
@import Network;
@import StoreKit;
@import WebKit;

@interface ISLineAdapter : LevelPlayBaseAdapter

@end
