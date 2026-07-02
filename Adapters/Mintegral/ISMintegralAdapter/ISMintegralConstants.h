//
//  ISMintegralConstants.h
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Mintegral";

// Configuration keys
static NSString * const appIdKey = @"appId";
static NSString * const appKeyKey = @"appKey";
static NSString * const placementIdKey = @"placementId";
static NSString * const unitIdKey = @"unitId";

// Bidding dictionary keys
static NSString * const adTypeKey = @"adType";

// Map keys
static NSString * const creativeIdKey = @"creativeId";
static NSString * const tokenKey = @"token";

// Meta data keys
static NSString * const metaDataCOPPAKey = @"Mintegral_COPPA";

// Channel code
static NSString * const channelCode = @"Y+H6DFttYrPQYcIb+F2F+F5/Hv==";
static NSString * const channelClassName = @"MTGSDK";
static NSString * const channelSelectorName = @"setChannelFlag:";

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logAppIdAndAppKey = @"appId = %@, appKey = %@";
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logPlacementIdAndUnitId = @"placementId = %@, unitId = %@";
static NSString * const logCreativeId = @"creativeId = %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"";
static NSString * const logInitFailed = @"Mintegral SDK init failed";
static NSString * const logInitFailedWithError = @"Mintegral SDK init failed: %@";

// Log strings - Token
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";

// Log strings - Load/Show/Legal/Error
static NSString * const logError = @"error = %@";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logLoadBanner = @"load banner with size %dX%d placementId = %@ unitId = %@";
static NSString * const logShowFailed = @"No ads to show";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const errorInterstitialAdInUse = @"Interstitial load request skipped. An interstitial ad with the same configuration is currently in use.";
static NSString * const errorRewardedAdInUse = @"Rewarded video load request skipped. A rewarded video ad with the same configuration is currently in use.";
static NSString * const logChannelCodeFailed = @"Failed to set channel code = %@";
static NSString * const logConsent = @"setConsentStatus = %@";
static NSString * const logCCPA = @"setDoNotTrackStatus = %@";
static NSString * const logCOPPA = @"value = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";

// Error codes
static const NSInteger mintegralNoFillEmptyError = -1;

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeLarge = @"LARGE";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeCustom = @"CUSTOM";

// Banner dimensions
static const CGFloat leaderboardWidth = 728;
static const CGFloat leaderboardHeight = 90;

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
