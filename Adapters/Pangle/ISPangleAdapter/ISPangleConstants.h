//
//  ISPangleConstants.h
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Pangle";

// Network keys
static NSString * const appIdKey = @"appID";
static NSString * const slotIdKey = @"slotID";

// Token key
static NSString * const tokenKey = @"token";

// Meta data keys
static NSString * const levelPlayAdxId = @"33";
static NSString * const metaDataCOPPAKey = @"Pangle_COPPA";

// Banner sizes
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const bannerSize = @"bannerSize";

// Banner dimensions
static const CGFloat bannerWidth = 320;
static const CGFloat bannerHeight = 50;
static const CGFloat rectangleWidth = 300;
static const CGFloat rectangleHeight = 250;
static const CGFloat leaderboardWidth = 728;
static const CGFloat leaderboardHeight = 90;

// Pangle error codes
static NSInteger const pangleNoFillErrorCode = 20001;
static NSInteger const pangleChildErrorCode = 20002;

// Pangle COPPA values
static NSInteger const pangleChildDirectedTypeChild = 1;
static NSInteger const pangleChildDirectedTypeNonChild = 0;
static NSInteger const pangleChildDirectedTypeDefault = -1;

// Init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED,
};

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logAppId = @"appId = %@";
static NSString * const logSlotId = @"slotId = %@";
static NSString * const logAppIdAndSlotId = @"appId = %@, slotId = %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"";
static NSString * const logInitError = @"Pangle SDK init failed %@";
static NSString * const logInitFailed = @"Pangle SDK init failed";

// Log strings - Token
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logTokenFailed = @"token is nil or empty";

// Log strings - Load/Show
static NSString * const logLoadFailed = @"%@ load failed";
static NSString * const logShowFailed = @"No ads to show";

// Log strings - Error
static NSString * const logError = @"error = %@";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logMissingSlotId = @"Missing slotId";
static NSString * const logMissingParam = @"Missing or invalid %@";

// Log strings - Legal/Consent
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"value = %@";
static NSString * const logCOPPA = @"coppaValue = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logChildError = @"Pangle_COPPA indicates the user is a child. Pangle SDK V71 or higher does not support child users.";
static NSString * const logGDPRError   = @"Manual configuration of GDPR information is no longer supported. Pangle will automatically read the settings from the CMP in the consent function.";

// Log strings - Consent values
static NSString * const logConsentTypeConsent = @"PAGPAConsentTypeConsent";
static NSString * const logConsentTypeNoConsent = @"PAGPAConsentTypeNoConsent";
static NSString * const logChildTypeChild = @"PANGLE_CHILD_DIRECTED_TYPE_CHILD";
static NSString * const logChildTypeNonChild = @"PANGLE_CHILD_DIRECTED_TYPE_NON_CHILD";
static NSString * const logChildTypeDefault = @"PANGLE_CHILD_DIRECTED_TYPE_DEFAULT";
