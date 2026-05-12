//
//  ISBidMachineConstants.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"BidMachine";

// Configuration keys
static NSString * const sourceIdKey = @"sourceId";
static NSString * const placementIdKey = @"placementId";

// Map keys
static NSString * const bannerSizeKey = @"bannerSize";
static NSString * const creativeIdKey = @"creativeId";
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCOPPAKey = @"BidMachine_COPPA";
static NSString * const metaDataCCPAConsentValue = @"1YN-";
static NSString * const metaDataCCPANoConsentValue = @"1YY-";

// Log format strings
static NSString * const logSourceId = @"sourceId = %@";
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logError = @"Error: %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"CCPA = %@";
static NSString * const logCOPPA = @"COPPA = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logLoadFailed = @"Failed to load %@ ad";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logToken = @"token = %@";
static NSString * const logTokenFailed = @"Failed to collect token";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logMetaDataSet = @"setMetaData key = %@, value = %@";
static NSString * const logCreativeId = @"creativeId = %@";
static NSString * const logEmptyCallback = @"";
static NSString * const logAdapterNil = @"Adapter instance is nil";
static NSString * const logMissingParam = @"Missing or invalid %@";

// Error codes
static const NSInteger bidMachineNoFillErrorCode = 103;

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";

// Init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
