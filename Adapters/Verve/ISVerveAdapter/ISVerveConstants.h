//
//  ISVerveConstants.h
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Verve";
static NSString * const mediationName = @"lp";

// Configuration keys
static NSString * const appTokenKey = @"appToken";
static NSString * const zoneIdKey = @"zoneId";

// Map keys
static NSString * const bannerSizeKey = @"bannerSize";
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCOPPAKey = @"LevelPlay_ChildDirected";
static NSString * const metaDataCCPAConsentValue = @"1YY-";
static NSString * const metaDataCCPANoConsentValue = @"1YN-";

// Log format strings
static NSString * const logAppToken = @"appToken = %@";
static NSString * const logZoneId = @"zoneId = %@";
static NSString * const logAppTokenAndZoneId = @"appToken = %@, zoneId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logCCPA = @"CCPA = %@";
static NSString * const logCOPPA = @"COPPA = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Init failed with error: %@";
static NSString * const logLoadFailed = @"Failed to load %@ ad with error: %@";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenFailed = @"Token is nil or empty";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logInitFailedMessage = @"Verve SDK init failed";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logMissingZoneId = @"Missing zoneId";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";


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

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
