//
//  ISPubMaticConstants.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"PubMatic";

// Configuration keys
static NSString * const publisherIdKey = @"publisherId";
static NSString * const profileIdKey = @"profileId";
static NSString * const adUnitIdKey = @"adUnitId";

// Map keys
static NSString * const bannerSizeKey = @"bannerSize";
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCOPPAKey = @"LevelPlay_ChildDirected";

// Log format strings
static NSString * const logAdUnitId = @"adUnitId = %@";
static NSString * const logPublisherIdAndProfileId = @"publisherId = %@, profileId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logCOPPA = @"COPPA = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailedMessage = @"PubMatic SDK init failed";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"Init must be completed successfully before fetching a token";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";

// Banner size descriptions
static NSString * const sizeRectangle = @"RECTANGLE";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
