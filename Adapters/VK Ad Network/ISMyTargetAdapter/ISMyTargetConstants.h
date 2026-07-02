//
//  ISMyTargetConstants.h
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"MyTarget";

// Configuration keys
static NSString * const slotIdKey = @"slotId";

// Bidding dictionary keys
static NSString * const tokenKey = @"token";

// Mediation custom param
static NSString * const mediationParamKey = @"mediation";
static NSString * const mediationParamValue = @"8";

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logSlotId = @"slotId = %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"";
static NSString * const logInitFailed = @"MyTarget SDK init failed";

// Log strings - Token
static NSString * const logToken = @"token = %@";

// Log strings - Load/Show/Legal/Error
static NSString * const logError = @"error = %@";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logLoadBanner = @"load banner with size %dX%d slotId = %@";
static NSString * const logShowFailed = @"No ads to show";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logConsent = @"setUserConsent = %@";

// Error messages
static NSString * const errorLoadFailed = @"MyTarget load failed, reason = %@";

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
