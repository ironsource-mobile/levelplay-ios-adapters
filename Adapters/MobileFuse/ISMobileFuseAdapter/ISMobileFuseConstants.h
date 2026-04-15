//
//  ISMobileFuseConstants.h
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"MobileFuse";
static NSString * const mediationName = @"unity_bidding";

// Configuration keys
static NSString * const placementIdKey = @"placementId";

// Map keys
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCOPPAKey = @"LevelPlay_ChildDirected";
static NSString * const metaDataCCPAConsentValue = @"1YY-";
static NSString * const metaDataCCPANoConsentValue = @"1YN-";
static NSString * const metaDataCCPADefaultValue = @"1-";

// Log format strings
static NSString * const logCallbackEmpty = @"";
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logMissingPlacementId = @"Missing placementId";
static NSString * const logAdapterNil = @"Adapter is nil";
static NSString * const logError = @"Error: %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"CCPA = %@";
static NSString * const logCOPPA = @"COPPA = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logLoadFailed = @"Failed to load %@ ad with error: %@";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenFailed = @"Failed to collect token";
static NSString * const logTokenError = @"Token collection not available - SDK not initialized";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logMetaDataSet = @"setMetaData key = %@, value = %@";
static NSString * const logNoFill = @"MobileFuse no fill";
static NSString * const logNoAdsToShow = @"%@ show failed";
static NSString * const logAdsExpired = @"ads are expired";

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeLeaderboard = @"LEADERBOARD";

// Init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// See MobileFuse SDK error codes here: https://docs.mobilefuse.com/docs/error-codes
typedef NS_ENUM(NSInteger, MobileFuseAdErrorCode)
{
    MobileFuseAlreadyLoaded = 1,
    MobileFuseRuntimeError = 3,
    MobileFuseAlreadyRendered = 4,
    MobileFuseLoadError = 5
};
