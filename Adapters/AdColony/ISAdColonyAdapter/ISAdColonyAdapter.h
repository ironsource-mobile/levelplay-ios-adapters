//
//  Copyright (c) 2015 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const AdColonyAdapterVersion = @"4.3.15";
static NSString * GitHash = @"";

//System Frameworks For AdColony Adapter

@import AdSupport;
@import AppTrackingTransparency;
@import AudioToolbox;
@import AVFoundation;
@import CoreMedia;
@import CoreServices;
@import CoreTelephony;
@import JavaScriptCore;
@import MessageUI;
@import SafariServices;
@import Social;
@import StoreKit;
@import SystemConfiguration;
@import WatchConnectivity;
@import WebKit;

@interface ISAdColonyAdapter : ISBaseAdapter

@end
