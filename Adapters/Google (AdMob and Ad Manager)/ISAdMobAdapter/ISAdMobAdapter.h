//
//  ISAdMobAdapter.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ISAdMobConstants.h>

static NSString * const AdMobAdapterVersion = @"4.3.48";
static NSString * Githash = @"";

//System Frameworks For AdMob Adapter

@import AdSupport;
@import AudioToolbox;
@import AVFoundation;
@import CFNetwork;
@import CoreGraphics;
@import CoreMedia;
@import CoreTelephony;
@import CoreVideo;
@import JavaScriptCore;
@import MediaPlayer;
@import MessageUI;
@import MobileCoreServices;
@import QuartzCore;
@import SafariServices;
@import Security;
@import StoreKit;
@import SystemConfiguration;
@import WebKit;

@interface ISAdMobAdapter : ISBaseAdapter

- (void)initAdMobSDKWithAdapterConfig:(ISAdapterConfig *)adapterConfig;

- (void)collectBiddingDataWithAdData:(GADRequest *)request
                            adFormat:(GADAdFormat)adFormat
                            delegate:(id<ISBiddingDataDelegate>)delegate;

- (GADRequest *)createGADRequestForLoadWithAdData:(NSDictionary *)adData
                                       serverData:(NSString *)serverData;

- (InitState)getInitState;

@end
