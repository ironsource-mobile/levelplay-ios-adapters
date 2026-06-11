//
//  ISInMobiConstants.h
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// Network name
static NSString * const networkName = @"InMobi";
static NSString * const mediationName = @"ironSource";

// Configuration keys
static NSString * const accountIdKey = @"accountId";
static NSString * const placementIdKey = @"placementId";
static NSString * const serverDataKey = @"serverData";

// Map keys
static NSString * const tokenKey = @"token";
static NSString * const creativeIdKey = @"creativeId";

// Metadata keys
static NSString * const metaDataAgeRestrictedKey = @"inMobi_AgeRestricted";
static NSString * const metaDataDoNotSellKey = @"do_not_sell";

// InMobi specific keys
static NSString * const tpKey = @"tp";
static NSString * const tpValueUnitylevelplay = @"c_unitylevelplay";
static NSString * const tpVersionKey = @"tp-ver";

// Log format strings
static NSString * const logAccountId = @"accountId = %@";
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logAccountIdAndPlacementId = @"accountId = %@, placementId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logSetLogLevel = @"setLogLevel - message = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Init failed with error: %@";
static NSString * const logInitFailedMessage = @"InMobi SDK init failed";
static NSString * const logCallbackEmpty = @"";
static NSString * const logLoadFailed = @"Failed to load %@ ad with error: %@";
static NSString * const logShowFailed = @"Failed to show %@ ad with error: %@";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenFailed = @"Returning nil as token since init failed";
static NSString * const logCreativeId = @"creativeId = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logAgeRestricted = @"Restricted = %@";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logAdIsNil = @"%@ ad is nil - can't continue";
static NSString * const logAdNotReady = @"%@ is not ready";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logInitStateSuccess = @"init %@: INIT_STATE_SUCCESS";

// Error messages
static NSString * const errorInMobiSDKInitFailed = @"InMobi SDK Init Failed";
static NSString * const errorNoFill = @"no fill";

// Banner size constants
static const CGFloat bannerWidth = 320;
static const CGFloat bannerHeight = 50;
static const CGFloat rectangleWidth = 300;
static const CGFloat rectangleHeight = 250;
static const CGFloat largeWidth = 728;
static const CGFloat largeHeight = 90;

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeLarge = @"LARGE";
static NSString * const sizeCustom = @"CUSTOM";
