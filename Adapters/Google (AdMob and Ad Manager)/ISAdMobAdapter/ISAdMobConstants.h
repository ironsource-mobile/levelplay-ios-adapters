//
//  ISAdMobConstants.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"AdMob";

// AdMob requires a request agent name
static NSString * const requestAgent = @"unity";
static NSString * const platformName = @"unity";

// AdMob network id
static NSString * const adMobNetworkId = @"GADMobileAds";

// Configuration keys
static NSString * const adUnitIdKey = @"adUnitId";

// Init configuration flags
static NSString * const networkOnlyInitKey = @"networkOnlyInit";
static NSString * const initResponseRequiredKey = @"initResponseRequired";

// Map keys
static NSString * const tokenKey = @"token";
static NSString * const sdkVersionKey = @"sdkVersion";
static NSString * const creativeIdKey = @"creativeId";
static NSString * const bannerSizeKey = @"bannerSize";

// AdData keys
static NSString * const adDataRequestIdKey = @"requestId";
static NSString * const adDataIsHybridKey = @"isHybrid";

// Additional parameters keys
static NSString * const platformNameKey = @"platform_name";
static NSString * const placementRequestIdKey = @"placement_req_id";
static NSString * const isHybridSetupKey = @"is_hybrid_setup";
static NSString * const nonPersonalizedAdsKey = @"npa";

// Additional parameters values
static NSString * const isHybridSetupTrueValue = @"true";
static NSString * const isHybridSetupFalseValue = @"false";
static NSString * const nonPersonalizedAdsValue = @"1";

// Bidding parameters
static NSString * const queryInfoTypeKey = @"query_info_type";
static NSString * const requesterType = @"requester_type_2";

// Metadata keys
static NSString * const metaDataTFCDKey = @"admob_tfcd";
static NSString * const metaDataTFUAKey = @"admob_tfua";
static NSString * const metaDataContentRatingKey = @"admob_maxcontentrating";
static NSString * const metaDataCCPAKey = @"gad_rdp";
static NSString * const metaDataContentMappingKey = @"google_content_mapping";

// Metadata content rating values
static NSString * const maxContentRatingG = @"max_ad_content_rating_g";
static NSString * const maxContentRatingPG = @"max_ad_content_rating_pg";
static NSString * const maxContentRatingT = @"max_ad_content_rating_t";
static NSString * const maxContentRatingMA = @"max_ad_content_rating_ma";

// Network data keys
static NSString * const networkDataContentMappingKey = @"ContentMapping";
static NSString * const networkDataContentRatingKey = @"MaxAdContentRating";

// Age configuration
static const NSInteger minUserAge = -1;
static const NSInteger maxChildAge = 13;

// Log format strings
static NSString * const logAdUnitId = @"adUnitId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logRatingValueNil = @"The ratingValue is nil";
static NSString * const logRatingValueUndefined = @"The ratingValue = %@ is undefined";
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"key = %@, value = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Init failed with error: %@";
static NSString * const logInitFailedMessage = @"AdMob SDK init failed";
static NSString * const logLoadFailed = @"Failed to load %@ ad with error: %@";
static NSString * const logShowFailed = @"Failed to show %@ ad with error: %@";
static NSString * const logToken = @"token = %@, sdkVersion = %@";
static NSString * const logTokenInitNotStarted = @"returning nil as token since init hasn't started";
static NSString * const logSignalFailed = @"Failed to create signal request";
static NSString * const logSignalNil = @"signal is nil";
static NSString * const logCreativeId = @"creativeId = %@";
static NSString * const logAdRewarded = @"adRewarded";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logUnsupportedBannerSize = @"AdMob unsupported banner size";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logHeadline = @"headline = %@";
static NSString * const logAdvertiser = @"advertiser = %@";
static NSString * const logBody = @"body = %@";
static NSString * const logCallToAction = @"callToAction = %@";
static NSString * const logIcon = @"icon url = %@";
static NSString * const logNativeAdViewNil = @"nativeAdView is nil";
static NSString * const logCallbackEmpty = @"";

// Error messages
static NSString * const errorShowFailed = @"%@ show failed";
static NSString * const errorAdIsNil = @"%@ ad is nil";
static NSString * const adFormatInterstitial = @"Interstitial";
static NSString * const adFormatRewarded = @"Rewarded";

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeLarge = @"LARGE";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeCustom = @"CUSTOM";

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
