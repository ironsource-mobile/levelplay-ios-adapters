//
//  ISFacebookAdapter.h
//  ISFacebookAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>
#import <ISFacebookConstants.h>

static NSString * const FacebookAdapterVersion = @"4.3.45";
static NSString * Githash = @"";

//System Frameworks For Facebook Adapter
@import AdSupport;
@import AudioToolbox;
@import AVFoundation;
@import CFNetwork;
@import CoreGraphics;
@import CoreImage;
@import CoreMedia;
@import CoreMotion;
@import CoreTelephony;
@import LocalAuthentication;
@import SafariServices;
@import Security;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import VideoToolbox;
@import WebKit;

@interface ISFacebookAdapter : ISBaseAdapter

- (void)initSDKWithPlacementIds:(NSString *)allPlacementIds;

- (NSDictionary *)getBiddingData;

- (InitState)getInitState;

@end
