//
//  ISUnityAdsAdapter.h
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>

static NSString * const UnityAdsAdapterVersion = @"5.8.0";
static NSString * Githash = @"";
static NSString * const UnityAdsAdapterName = @"UnityAds";

static NSInteger const TROUBLESHOOTING_UADS_MISSING_CALLBACK = 80600;

typedef void(^ISUnityAdsEventSenderBlock)(NSString * _Nonnull adFormat, NSInteger eventId, NSString * _Nonnull ext1);

//System Frameworks For UnityAds Adapter

@import AdSupport;
@import CoreTelephony;
@import StoreKit;

@interface ISUnityAdsAdapter : ISBaseAdapter

@end
