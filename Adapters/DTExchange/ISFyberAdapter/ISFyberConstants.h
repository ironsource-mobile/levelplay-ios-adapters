//
//  ISFyberConstants.h
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Fyber";

// Configuration keys
static NSString * const appIdKey = @"appId";
static NSString * const spotIdKey = @"adSpotId";

// Bidding dictionary keys
static NSString * const tokenKey = @"token";

// Meta data keys
static NSString * const metaDataCOPPAKey = @"DT_COPPA";

// CCPA strings
static NSString * const ccpaConsentString = @"1YN-";
static NSString * const ccpaDoNotSellString = @"1YY-";

// Request configuration
static const NSInteger requestTimeOut = 15;

// Error codes
static const NSInteger fyberNoFillErrorCode = 204;

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logInitAppId = @"Initialize Fyber with appId = %@";
static NSString * const logSpotId = @"spotId = %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"Fyber SDK init success";
static NSString * const logInitFailed = @"Fyber SDK init failed";
static NSString * const logInitFailedWithError = @"Fyber SDK init failed %@";

// Log strings - Token
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";

// Log strings - Legal
static NSString * const logSetUserId = @"set userID to %@";
static NSString * const logConsent = @"setGDPRConsent = %@";
static NSString * const logCCPA = @"setCCPAString = %@";
static NSString * const logCOPPA = @"coppaApplies = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";

// Log strings - Load/Show/Error
static NSString * const logError = @"error = %@";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logLoadBanner = @"load banner with size %dX%d spotId = %@";
static NSString * const logMissingParam = @"Missing or invalid %@";

// Error messages
static NSString * const errorShowFailed = @"Fyber show failed";
static NSString * const errorLoadFailed = @"Fyber load failed";
static NSString * const errorExpiredAds = @"ads are expired";
static NSString * const errorUnsupportedBannerSize = @"Fyber unsupported banner size";

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";

// Banner dimensions
static const CGFloat bannerWidth = 320;
static const CGFloat bannerHeight = 50;
static const CGFloat rectangleWidth = 300;
static const CGFloat rectangleHeight = 250;
static const CGFloat leaderboardWidth = 728;
static const CGFloat leaderboardHeight = 90;

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
