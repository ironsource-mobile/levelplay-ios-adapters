//
//  ISChartboostConstants.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Chartboost";
static NSString * const mediationName = @"ironSource";

// Configuration keys
static NSString * const appIdKey = @"appID";
static NSString * const appSignatureKey = @"appSignature";
static NSString * const locationIdKey = @"adLocation";

// Map keys
static NSString * const creativeIdKey = @"creativeId";
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCOPPAKey = @"CHARTBOOST_COPPA";

// Log format strings
static NSString * const logLocationId = @"locationId = %@";
static NSString * const logCreativeId = @"creativeId = %@";
static NSString * const logAppIdAndAppSignature = @"appId = %@, appSignature = %@";
static NSString * const logError = @"error = %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"CCPA = %@";
static NSString * const logCOPPA = @"COPPA = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Init failed with error: %@";
static NSString * const logInitFailedMessage = @"Chartboost SDK init failed";
static NSString * const logLoadFailed = @"Failed to load %@ ad with error: %@";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logAdExpired = @"ads are expired";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";

// Banner size constants
static const CGFloat customBannerMinHeight = 40;
static const CGFloat customBannerMaxHeight = 60;

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeLarge = @"LARGE";
static NSString * const sizeCustom = @"CUSTOM";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
