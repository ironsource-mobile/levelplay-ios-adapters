//
//  ISAdMobConstants.h
//  ISAdMobAdapter
//
//  Created by Hadar Pur on 20/04/2023.
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>

//AdMob requires a request agent name
static NSString * const kRequestAgent             = @"unity";
static NSString * const kPlatformName             = @"unity";

static NSString * const kAdapterName              = @"AdMob";
static NSString * const kAdUnitId                 = @"adUnitId";
static NSString * const kIsNative                 = @"isNative";

static int const kMinUserAge                      = -1;
static int const kMaxChildAge                     = 13;

// AdMob network id
static NSString * const kAdMobNetworkId           = @"GADMobileAds";

// AdMob banner bidding parameters
static NSString * const kAdMobQueryInfoType        = @"query_info_type";
static NSString * const kAdMobRequesterType        = @"requester_type_2";
static NSString * const kAdMobAdaptiveBannerWidth  = @"adaptive_banner_w";
static NSString * const kAdMobAdaptiveBannerHeight = @"adaptive_banner_h";

// Init configuration flags
static NSString * const kNetworkOnlyInitFlag      = @"networkOnlyInit";
static NSString * const kInitResponseRequiredFlag = @"initResponseRequired";

// Meta data keys
static NSString * const kAdMobTFCD                = @"admob_tfcd";
static NSString * const kAdMobTFUA                = @"admob_tfua";
static NSString * const kAdMobContentRating       = @"admob_maxcontentrating";
static NSString * const kAdMobCCPAKey             = @"gad_rdp";
static NSString * const kAdMobContentMapping      = @"google_content_mapping";

// Meta data content rate values
static NSString * const kAdMobMaxContentRatingG    = @"max_ad_content_rating_g";
static NSString * const kAdMobMaxContentRatingPG   = @"max_ad_content_rating_pg";
static NSString * const kAdMobMaxContentRatingT    = @"max_ad_content_rating_t";
static NSString * const kAdMobMaxContentRatingMA   = @"max_ad_content_rating_ma";

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
