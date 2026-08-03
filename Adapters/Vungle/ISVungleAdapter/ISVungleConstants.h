//
//  ISVungleConstants.h
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Vungle";
static NSString * const mediationName = @"ironsource";

// Configuration keys
static NSString * const appIdKey = @"AppID";
static NSString * const placementIdKey = @"PlacementId";

// Map keys
static NSString * const creativeIdKey = @"creativeId";
static NSString * const tokenKey = @"token";

// Adapter ad format identifiers
static NSString * const adapterFormatRewarded     = @"ISVungleRewardedVideo";
static NSString * const adapterFormatInterstitial = @"ISVungleInterstitial";
static NSString * const adapterFormatBanner       = @"ISVungleBanner";

// Meta data keys
static NSString * const metaDataCOPPAKey = @"Vungle_COPPA";

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logAppId = @"appId = %@";
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logCreativeId = @"creativeId = %@";
static NSString * const logSetUserId = @"set userID to %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Vungle SDK init failed";
static NSString * const logInitFailedWithError = @"Vungle SDK init failed: %@";

// Log strings - Token
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";

// Log strings - Load/Show/Legal/Error
static NSString * const logError = @"error = %@";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logShowFailed = @"No ads to show";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"optIn = %@";
static NSString * const logCOPPA = @"value = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logCustomBannerSizeMismatch = @"CustomBannerSizeMismatch:w-%ld|h-%ld";

// Banner size descriptions
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeLeaderboard = @"LEADERBOARD";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeCustom = @"CUSTOM";

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
