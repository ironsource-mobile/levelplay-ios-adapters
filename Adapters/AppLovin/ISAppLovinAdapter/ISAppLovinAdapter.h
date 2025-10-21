//
//  ISAppLovinAdapter.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <AppLovinSDK/AppLovinSDK.h>

static NSString * const AppLovinAdapterVersion = @"5.1.0";
static NSString * Githash = @"";

//System Frameworks For AppLovin Adapter
@import AdSupport;
@import AppTrackingTransparency;
@import AudioToolbox;
@import AVFoundation;
@import CFNetwork;
@import CoreGraphics;
@import CoreMedia;
@import CoreMotion;
@import CoreTelephony;
@import MessageUI;
@import SafariServices;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import WebKit;

@interface ISAppLovinAdapter : ISBaseAdapter

- (void)disposeInterstitialAdWithZoneId:(NSString *)zoneId;

@end
