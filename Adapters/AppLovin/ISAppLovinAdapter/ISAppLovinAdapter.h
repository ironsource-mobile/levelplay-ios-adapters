//
//  ISAppLovinAdapter.h
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>

static NSString * const AppLovinAdapterVersion = @"4.3.51";
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

- (void)disposeRewardedVideoAdWithZoneId:(NSString *)zoneId;

- (void)disposeInterstitialAdWithZoneId:(NSString *)zoneId;

@end
