//
//  ISHyprMXConstants.h
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"HyprMX";
static NSString * const mediationName = @"ironsource";

// Configuration keys
static NSString * const distributorIdKey = @"distributorId";
static NSString * const propertyIdKey = @"propertyId";

// Map keys
static NSString * const tokenKey = @"token";

// Meta data keys
static NSString * const metaDataAgeRestrictionKey = @"HyprMX_ageRestricted";

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logPropertyId = @"propertyId = %@";
static NSString * const logDistributorIdAndPropertyId = @"distributorId = %@, propertyId = %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"";
static NSString * const logInitFailed = @"HyprMX SDK init failed";

// Log strings - Token
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logTokenFailed = @"Failed to get token";

// Log strings - Load/Show/Legal/Error
static NSString * const logError = @"error = %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logAgeRestriction = @"value = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logLoadNoFill = @"HyprMX no fill";
static NSString * const logShowFailed = @"No ads to show";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logUnsupportedBannerSize = @"unsupported banner size - %@";
static NSString * const errorInterstitialAdInUse = @"Interstitial load request skipped. An interstitial ad with the same configuration is currently in use.";
static NSString * const errorRewardedAdInUse = @"Rewarded video load request skipped. A rewarded video ad with the same configuration is currently in use.";

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
