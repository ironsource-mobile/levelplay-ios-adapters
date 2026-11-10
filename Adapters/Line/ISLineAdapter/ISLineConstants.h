//
//  ISLineConstants.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Line";

// Configuration keys
static NSString * const appIdKey = @"appId";
static NSString * const slotIdKey = @"slotId";

// Map keys
static NSString * const tokenKey = @"token";

// Log format strings
static NSString * const logAppIdAndSlotId = @"appId = %@, slotId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailedMessage = @"Line SDK init failed";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logNoAdsToShow = @"No ads to show";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenFailed = @"Token is nil or empty";
static NSString * const logTokenError = @"returning nil as token since init hasn't started";
static NSString * const logAdLoaderNil = @"adLoader is nil";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logNoAd = @"no ad";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";

// Error codes
static NSInteger const lineNoFillErrorCode = 2; // kFADErrorCodeNoAd

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
