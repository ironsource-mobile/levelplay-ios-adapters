//
//  ISYSOConstants.h
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"YSO";

// Configuration keys
static NSString * const placementKeyKey = @"placementKey";

// Map keys
static NSString * const tokenKey = @"token";
static NSString * const sdkVersionKey = @"sdkVersion";

// Log format strings
static NSString * const logPlacementKey = @"placementKey = %@";
static NSString * const logError = @"error = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailedMessage = @"YSO SDK init failed";
static NSString * const logInitException = @"YSO initialization exception: %@";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logNoAdsToShow = @"No ads to show";
static NSString * const logToken = @"token = %@, sdkVersion = %@";
static NSString * const logTokenFailed = @"Failed to receive token";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";

// YSO load error descriptions
static NSString * const errorSdkNotInitialized = @"sdk not initialized";
static NSString * const errorInvalidRequest = @"bad request data sent to SDK";
static NSString * const errorInvalidConfig = @"invalid ad configuration";
static NSString * const errorLoad = @"ad load error";
static NSString * const errorTimeout = @"timeout loading the ad";
static NSString * const errorServer = @"error in the server response";
static NSString * const errorInternal = @"other error";
static NSString * const errorUnknown = @"unknown error";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
