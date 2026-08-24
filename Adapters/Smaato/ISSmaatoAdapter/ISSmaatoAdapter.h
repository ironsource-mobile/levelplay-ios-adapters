//
//  ISSmaatoAdapter.h
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const SmaatoAdapterVersion = @"5.5.0";
static NSString * Githash = @"";

//System Frameworks For Smaato Adapter
@import AdSupport;
@import AVFoundation;
@import CoreMedia;
@import CoreTelephony;
@import StoreKit;
@import SafariServices;
@import SystemConfiguration;
@import WebKit;

@interface ISSmaatoAdapter : LevelPlayBaseAdapter

@end
