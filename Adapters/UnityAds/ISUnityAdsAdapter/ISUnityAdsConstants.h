//
//  ISUnityAdsConstants.h
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"UnityAds";
static NSString * const mediationName = @"ironSource";

// Configuration keys
static NSString * const gameIdKey = @"sourceId";
static NSString * const placementIdKey = @"zoneId";
static NSString * const unityAdsInitBlobKey = @"uads_init_blob";
static NSString * const unityAdsEpTraitsKey = @"traits";

// Map keys
static NSString * const bannerSizeKey = @"bannerSize";
static NSString * const tokenKey = @"token";

// Metadata keys
static NSString * const metaDataCOPPAKey = @"unityads_coppa";
static NSString * const ccpaUnityAdsFlag = @"privacy.consent";
static NSString * const gdprUnityAdsFlag = @"gdpr.consent";
static NSString * const coppaUnityAdsFlag = @"user.nonBehavioral";

// Log format strings
static NSString * const logPlacementId = @"placementId = %@";
static NSString * const logGameIdAndPlacementId = @"gameId = %@, placementId = %@";
static NSString * const logError = @"error = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logInitFailedWithError = @"UnityAds SDK init failed with error code: %@, error message: %@";
static NSString * const logInitFailedMessage = @"UnityAds SDK init failed";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logUnsupportedBannerSize = @"UnityAds unsupported banner size - %@";
static NSString * const logToken = @"token = %@";
static NSString * const logEmptyToken = @"empty token";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logCallbackEmpty = @"";

// UnityAds error codes
static const NSInteger unityAdsNoFillErrorCode = 52100;

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
static NSString * const sizeLarge = @"LARGE";

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
