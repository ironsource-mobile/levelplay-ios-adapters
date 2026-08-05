//
//  ISFyberAdapter.h
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const FyberAdapterVersion = @"5.12.0";
static NSString * Githash = @"";

// System Frameworks For Fyber Adapter
@import AdSupport;
@import AVFoundation;
@import CoreGraphics;
@import CoreMedia;
@import CoreTelephony;
@import MediaPlayer;
@import StoreKit;
@import SystemConfiguration;
@import WebKit;

@interface ISFyberAdapter : LevelPlayBaseAdapter

@end
