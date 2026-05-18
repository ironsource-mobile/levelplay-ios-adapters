//
//  ISBigoConstants.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"Bigo";
static NSString * const mediationName = @"LevelPlay";

// Mediation info keys
static NSString * const mediationNameKey = @"mediationName";
static NSString * const mediationVersionKey = @"mediationVersion";
static NSString * const adapterVersionKey = @"adapterVersion";

// Network keys
static NSString * const appIdKey = @"appId";
static NSString * const slotIdKey = @"slotId";

// Token key
static NSString * const tokenKey = @"token";

// Meta data keys
static NSString * const metaDataCOPPAKey = @"LevelPlay_ChildDirected";

// Banner sizes
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const bannerSizeKey = @"bannerSize";

// Banner dimensions
static const CGFloat bannerWidth = 320;
static const CGFloat bannerHeight = 50;
static const CGFloat rectangleWidth = 300;
static const CGFloat rectangleHeight = 250;
static const CGFloat leaderboardWidth = 728;
static const CGFloat leaderboardHeight = 90;

// Log strings - General
static NSString * const logCallbackEmpty = @"";

// Log strings - Network configuration
static NSString * const logAppId = @"appId = %@";
static NSString * const logSlotId = @"slotId = %@";
static NSString * const logAppIdAndSlotId = @"appId = %@, slotId = %@";

// Log strings - Initialization
static NSString * const logInitSuccess = @"";
static NSString * const logInitFailed = @"Bigo SDK init failed";

// Log strings - Token
static NSString * const logToken = @"token = %@";
static NSString * const logTokenError = @"returning nil as token since init hasn't finished successfully";
static NSString * const logTokenFailed = @"Failed to get bidder token";

// Log strings - Load/Show
static NSString * const logLoadFailed = @"%@ load failed";
static NSString * const logShowFailed = @"No ads to show";
static NSString * const logUnsupportedBannerSize = @"Bigo unsupported banner size";

// Log strings - Error
static NSString * const logError = @"error = %@";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logMissingSlotId = @"Missing slotId";
static NSString * const logMissingParam = @"Missing or invalid %@";

// Log strings - Legal/Consent
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"value = %@";
static NSString * const logCOPPA = @"value = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
