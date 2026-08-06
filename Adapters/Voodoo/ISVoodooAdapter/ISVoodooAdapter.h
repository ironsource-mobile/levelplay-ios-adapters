//
//  ISVoodooAdapter.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const VoodooAdapterVersion = @"5.4.0";
static NSString * Githash = @"";

//System Frameworks For Voodoo Adapter
@import AdSupport;
@import AppTrackingTransparency;
@import AVFoundation;
@import CoreTelephony;
@import Network;
@import QuartzCore;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import WebKit;

@interface ISVoodooAdapter : LevelPlayBaseAdapter

@end
