//
//  ISAdColonyAdapter.h
//  ISAdColonyAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>

static NSString * const AdColonyAdapterVersion = @"4.3.17";
static NSString * Githash = @"";

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
