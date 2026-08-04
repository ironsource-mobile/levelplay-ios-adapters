//
//  ISOguryConstants.h
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Ogury";
static NSString * const mediationName = @"Unity LevelPlay";

// Configuration keys
static NSString * const assetKeyKey = @"assetKey";
static NSString * const adUnitIdKey = @"adUnitId";

// Map keys
static NSString * const tokenKey = @"token";

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logAdUnitId = @"adUnitId = %@";
static NSString * const logAssetKeyAndAdUnitId = @"assetKey = %@, adUnitId = %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Ogury SDK init failed";

// Log strings - Token
static NSString * const logToken = @"token = %@";

// Log strings - Load/Show/Error
static NSString * const logError = @"error = %@";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logShowFailed = @"No ads to show";
static NSString * const logTokenFailed = @"Failed to receive token - Ogury";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";

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
