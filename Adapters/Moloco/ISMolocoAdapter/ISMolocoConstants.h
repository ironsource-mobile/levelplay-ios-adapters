//
//  ISMolocoConstants.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Moloco";
static NSString * const mediationName = @"LevelPlay";

// Configuration keys
static NSString * const appKeyKey = @"appKey";
static NSString * const adUnitIdKey = @"adUnitId";
static NSString * const serverDataKey = @"serverData";

// Map keys
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCOPPAKey = @"Moloco_COPPA";

// Log format strings
static NSString * const logAdUnitId = @"adUnitId = %@";
static NSString * const logAppKeyAndAdUnitId = @"appKey = %@, adUnitId = %@";
static NSString * const logError = @"Error: %@";
static NSString * const logAdapterNil = @"Adapter is nil";
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"CCPA = %@";
static NSString * const logCOPPA = @"COPPA = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Init failed";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";
static NSString * const logCallbackFailed = @"adUnitId = %@, error = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";

// Error messages
static NSString * const errorInterstitialNotAvailable = @"Interstitial ad not available";
static NSString * const errorRewardedNotAvailable = @"Rewarded ad not available";

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";

// Init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
