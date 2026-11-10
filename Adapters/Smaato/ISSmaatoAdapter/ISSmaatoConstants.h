//
//  ISSmaatoConstants.h
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Smaato";

// Configuration keys
static NSString * const adSpaceIdKey = @"adspaceID";
static NSString * const publisherIdKey = @"publisherId";

// Map keys
static NSString * const creativeIdKey = @"creativeId";
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCCPAKey = @"IABUSPrivacy_String";
static NSString * const metaDataCCPANoConsentValue = @"1YYN";
static NSString * const metaDataCCPAConsentValue = @"1YNN";

// Log format strings
static NSString * const logAdSpaceId = @"adSpaceId = %@";
static NSString * const logCreativeId = @"creativeId = %@";
static NSString * const logPublisherId = @"publisherId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailedMessage = @"Smaato SDK init failed";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logNoFill = @"Smaato no fill";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logAdRequestFailed = @"Error while creating Smaato AdRequestParams";
static NSString * const logAdExpired = @"ads are expired";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";

// Banner size constants
static const CGFloat bannerWidth = 320;
static const CGFloat bannerHeight = 50;
static const CGFloat rectangleWidth = 300;
static const CGFloat rectangleHeight = 250;
static const CGFloat leaderboardWidth = 728;
static const CGFloat leaderboardHeight = 90;

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";

// Init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
