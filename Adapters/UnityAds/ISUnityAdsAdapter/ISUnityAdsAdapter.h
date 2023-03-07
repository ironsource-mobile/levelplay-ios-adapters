//
//  ISUnityAdsAdapter.h
//  ISUnityAdsAdapter
//
//  Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const UnityAdsAdapterVersion = @"4.3.26";
static NSString * Githash = @"";

//System Frameworks For UnityAds Adapter

@import AdSupport;
@import CoreTelephony;
@import StoreKit;

@interface ISUnityAdsAdapter : ISBaseAdapter

@end
