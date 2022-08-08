//
//  ISUnityAdsAdapter.h
//  ISUnityAdsAdapter
//
//  Created by Clementine on 2/4/15.
//  Copyright (c) 2015 Clementine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const UnityAdsAdapterVersion = @"4.3.23";
static NSString * Githash = @"";

//System Frameworks For UnityAds Adapter

@import AdSupport;
@import CoreTelephony;
@import StoreKit;

@interface ISUnityAdsAdapter : ISBaseAdapter

@end
