//
//  ISFacebookConstants.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Facebook";
static NSString * const mediationName = @"IronSource";

// Configuration keys
static NSString * const placementIdKey = @"placementId";
static NSString * const placementIdsKey = @"placementIds";
static NSString * const serverDataKey = @"serverData";

// Map keys
static NSString * const tokenKey = @"token";

// Mediation service format: <mediationName>_<sdkVersion>:<adapterVersion>
static NSString * const mediationServiceFormat = @"%@_%@:%@";

// Metadata keys
static NSString * const metaDataMixedAudienceKey = @"meta_mixed_audience";

// Error codes
static const NSInteger facebookNoFillErrorCode = 1001;

// Log format strings
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logPlacementIds = @"Initialize Meta with placementIds = %@";
static NSString * const logError = @"error = %@";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Init failed";
static NSString * const logInitFailedMessage = @"Meta SDK init failed";
static NSString * const logLoadFailed = @"Failed to load %@ ad with error: %@";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenFailed = @"Returning nil as token since init failed";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logMixedAudience = @"isMixedAudience = %@";
static NSString * const logTestMode = @"setTestMode = %@";
static NSString * const logMediationService = @"mediationService = %@";
static NSString * const logUnsupportedBannerSize = @"Meta unsupported banner size";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logHeadline = @"headline = %@";
static NSString * const logAdvertiser = @"advertiser = %@";
static NSString * const logBody = @"body = %@";
static NSString * const logCallToAction = @"callToAction = %@";
static NSString * const logNativeAdViewNil = @"nativeAdView is nil";
static NSString * const logCallbackEmpty = @"";

// Error messages
static NSString * const errorShowFailed = @"%@ show failed";

// Banner size constants
static const CGFloat bannerWidth = 320;
static const CGFloat bannerHeight = 50;
static const CGFloat largeHeight = 90;
static const CGFloat rectangleWidth = 300;
static const CGFloat rectangleHeight = 250;
static const CGFloat leaderboardWidth = 728;
static const CGFloat leaderboardHeight = 90;

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeLarge = @"LARGE";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeCustom = @"CUSTOM";

// Native ad options view constants
static const CGFloat adOptionsViewTopMargin = 15;

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
