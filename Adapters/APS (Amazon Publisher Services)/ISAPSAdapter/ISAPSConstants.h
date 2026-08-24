//
//  ISAPSConstants.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network name
static NSString * const networkName = @"APS";

// Configuration keys
static NSString * const uuidKey = @"uuid";
static NSString * const apsFormatKey = @"apsFormat";
static NSString * const dimensionsKey = @"dimensions";
static NSString * const widthDimensionKey = @"w";
static NSString * const heightDimensionKey = @"h";

// Map keys
static NSString * const pricePointEncodedKey = @"pricePointEncoded";
static NSString * const widthKey = @"width";
static NSString * const heightKey = @"height";

// Ad format values
static NSString * const videoAdType = @"video";

// U.S. Privacy String (CCPA) custom target
static NSString * const usPrivacyKey = @"us_privacy";
static NSString * const usPrivacyNotApplicable = @"1---";
static NSString * const usPrivacyOptIn = @"1YN-";
static NSString * const usPrivacyOptOut = @"1YY-";

// Log format strings
static NSString * const logUuid = @"uuid = %@";
static NSString * const logToken = @"token = %@";
static NSString * const logError = @"error = %@";
static NSString * const logCCPA = @"CCPA opt-out = %@";
static NSString * const logMetaDataSet = @"key = %@, value = %@";
static NSString * const logUSPrivacy = @"%@ = %@";
static NSString * const logShowFailed = @"Failed to show %@ ad";
static NSString * const logAdResponseMissing = @"adResponse is missing";
static NSString * const logAdapterNil = @"Network adapter is nil";
static NSString * const logUnsupportedBannerSize = @"Unsupported banner size";
static NSString * const logMissingConfigurationParam = @"Missing APS LevelPlay Platform configuration: %@";
static NSString * const logInvalidAdSize = @"Missing APS LevelPlay Platform configuration: ad size (%ld, %ld)";
static NSString * const logErrorReason = @"errorReason = %@";
static NSString * const logAPSHandledByMediation = @"APS loading is handled by Mediation and does not require any additional implementation in your code.";
static NSString * const logCallbackEmpty = @"";

// APS error descriptions
static NSString * const errorBadRequest = @"Bad request";
static NSString * const errorUnknown = @"Unknown error";
static NSString * const errorNetwork = @"Network error";
static NSString * const errorNoInventory = @"No Inventory";
static NSString * const errorUnknownCode = @"unknown error code: %d";
static NSString * const errorNetworkError = @"Network Error";
static NSString * const errorUnknownError = @"Unknown Error";
static NSString * const errorNetworkTimeout = @"Network Timeout";
static NSString * const errorNoFill = @"No Fill";
static NSString * const errorInternal = @"Internal Error";
static NSString * const errorRequest = @"Request Error";

// Video ad size constants
static const NSInteger videoPortraitWidth = 320;
static const NSInteger videoPortraitHeight = 480;
static const NSInteger videoLandscapeWidth = 480;
static const NSInteger videoLandscapeHeight = 320;

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
