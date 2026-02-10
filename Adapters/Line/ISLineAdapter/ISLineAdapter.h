//
//  ISLineAdapter.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <FiveAd/FiveAd.h>

static NSString * const LineAdapterVersion = @"5.3.0";
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

@interface ISLineAdapter : ISBaseAdapter

- (FADAdLoader *)getAdLoader:(NSString *)appId;

@end
