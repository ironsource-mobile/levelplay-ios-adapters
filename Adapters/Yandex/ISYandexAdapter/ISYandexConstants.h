//
//  ISYandexConstants.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

// Network Identification
static NSString * const networkName                 = @"Yandex";

// Network keys
static NSString * const appIdKey                    = @"appId";
static NSString * const adUnitIdKey                 = @"adUnitId";

// Mediation Keys
static NSString * const mediationName               = @"ironsource";
static NSString * const tokenKey                    = @"token";
static NSString * const creativeIdKey               = @"creativeId";
static NSString * const bannerSizeKey               = @"bannerSize";

// Adapter Parameters Keys
static NSString * const adapterVersionKey           = @"adapter_version";
static NSString * const adapterNetworkNameKey       = @"adapter_network_name";
static NSString * const adapterNetworkSDKVersionKey = @"adapter_network_sdk_version";

// Yandex errors
static NSInteger yandexNoFillErrorCode              = 7; // YMAAdErrorCodeNoFill

// Logging Messages
static NSString * const logAdUnitId                 = @"adUnitId = %@";
static NSString * const logAppId                    = @"appId = %@";
static NSString * const logError                    = @"error = %@";
static NSString * const logCreativeId               = @"creativeId = %@";
static NSString * const logCallbackFailed           = @"adUnitId = %@ with error = %@";
static NSString * const logCallbackEmpty            = @"";

// Meta data
static NSString * const logConsent                  = @"consent = %@";

// Token
static NSString * const logToken                    = @"token = %@";
static NSString * const logTokenError               = @"returning nil as token since init hasn't finished successfully";

// Show failed
static NSString * const logShowFailed               = @"%@ show failed";

// Adapter internal error
static NSString * const logAdapterNil               = @"Network adapter is nil";
static NSString * const logMissingAdUnitId          = @"Missing adUnitId";

// Banner sizes
static NSString * const sizeBanner                  = @"BANNER";
static NSString * const sizeLarge                   = @"LARGE";
static NSString * const sizeRectangle               = @"RECTANGLE";
static NSString * const sizeSmart                   = @"SMART";
static NSString * const sizeCustom                  = @"CUSTOM";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
