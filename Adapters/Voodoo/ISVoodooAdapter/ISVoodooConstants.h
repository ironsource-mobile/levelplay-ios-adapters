//
//  ISVoodooConstants.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Voodoo";
static NSString * const mediationName = @"ironsource";

// Configuration keys
static NSString * const placementIdKey = @"placementId";

// Map keys
static NSString * const tokenKey = @"token";
static NSString * const sdkVersionKey = @"sdkVersion";

// Log format strings
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailed = @"Voodoo SDK init failed";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logToken = @"token = %@, sdkVersion = %@";
static NSString * const logTokenFailed = @"Failed to receive token - Voodoo";
static NSString * const logTokenError = @"returning nil as token since init hasn't started";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";

// Error codes
static NSInteger const voodooNoFillErrorCode = -204; // AdnErrorNoFill

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
