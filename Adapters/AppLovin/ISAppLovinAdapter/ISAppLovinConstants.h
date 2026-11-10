//
//  ISAppLovinConstants.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"AppLovin";

// Configuration keys
static NSString * const sdkKeyKey = @"sdkKey";
static NSString * const zoneIdKey = @"zoneId";

// Log format strings
static NSString * const logZoneId = @"zoneId = %@";
static NSString * const logSdkKeyAndZoneId = @"sdkKey = %@, zoneId = %@";
static NSString * const logSdkKeyAndVerboseLogging = @"sdkKey = %@, isVerboseLogging = %d";
static NSString * const logError = @"error = %@";
static NSString * const logConsent = @"consent = %@";
static NSString * const logCCPA = @"CCPA = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logInitSuccess = @"Init success";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logAdCreationFailed = @"Failed to create %@ ad object";
static NSString * const errorInterstitialAdInUse = @"Interstitial load request skipped. An interstitial ad with the same configuration is currently in use.";
static NSString * const errorRewardedAdInUse = @"Rewarded video load request skipped. A rewarded video ad with the same configuration is currently in use.";
static NSString * const logSetUserId = @"set userID to %@";
static NSString * const logMissingParam = @"Missing or invalid %@";
static NSString * const logBannerViewNil = @"bannerView is nil";
static NSString * const logCallbackEmpty = @"";

// AppLovin error descriptions
static NSString * const errorSdkDisabled = @"The SDK is currently disabled.";
static NSString * const errorNoFill = @"No ads are currently eligible for your device & location.";
static NSString * const errorNetworkTimeout = @"A fetch ad request timed out (usually due to poor connectivity).";
static NSString * const errorNotConnected = @"The device is not connected to internet (for instance if user is in Airplane mode).";
static NSString * const errorUnspecified = @"An unspecified network issue occured.";
static NSString * const errorUnableToRender = @"There has been a failure to render an ad on screen.";
static NSString * const errorInvalidZone = @"The zone provided is invalid; the zone needs to be added to your AppLovin account or may still be propagating to our servers.";
static NSString * const errorInvalidAdToken = @"The provided ad token is invalid; ad token must be returned from AppLovin S2S integration.";
static NSString * const errorPrecacheResources = @"An attempt to cache a resource to the filesystem failed; the device may be out of space.";
static NSString * const errorPrecacheImage = @"An attempt to cache an image resource to the filesystem failed; the device may be out of space.";
static NSString * const errorPrecacheVideo = @"An attempt to cache a video resource to the filesystem failed; the device may be out of space.";
static NSString * const errorInvalidResponse = @"The AppLovin servers have returned an invalid response.";
static NSString * const errorNotPreloaded = @"The developer called for a rewarded video before one was available.";
static NSString * const errorUnknownServer = @"An unknown server-side error occurred.";
static NSString * const errorValidationTimeout = @"A reward validation requested timed out (usually due to poor connectivity)";
static NSString * const errorUserClosedVideo = @"The user exited out of the video early. You may or may not wish to grant a reward depending on your preference.";
static NSString * const errorInvalidURL = @"A postback URL you attempted to dispatch was empty or nil.";
static NSString * const errorPrecacheHTML = @"An attempt to cache an HTML resource to the filesystem failed; the device may be out of space.";
static NSString * const errorInvalidBody = @"The request was invalid due to a malformed body.";
static NSString * const errorUnknownCode = @"Unknown error code %d";

// Banner size constants
static const CGFloat bannerWidth = 320;
static const CGFloat bannerHeight = 50;
static const CGFloat rectangleWidth = 300;
static const CGFloat rectangleHeight = 250;
static const CGFloat largeWidth = 728;
static const CGFloat largeHeight = 90;
static const CGFloat customBannerMinHeight = 40;
static const CGFloat customBannerMaxHeight = 60;

// Banner size descriptions
static NSString * const sizeBanner = @"BANNER";
static NSString * const sizeRectangle = @"RECTANGLE";
static NSString * const sizeSmart = @"SMART";
static NSString * const sizeLarge = @"LARGE";

// init state possible values - AppLovin reports init success only
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
