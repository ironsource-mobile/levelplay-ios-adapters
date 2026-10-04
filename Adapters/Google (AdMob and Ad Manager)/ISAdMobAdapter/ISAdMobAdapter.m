//
//  ISAdMobAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"

// Init state
static InitState initState = INIT_STATE_NONE;

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

// Consent flags
static BOOL didSetConsentCollectingUserData      = NO;
static BOOL consentCollectingUserData            = NO;
static NSString *contentMappingURLValue          = @"";
static NSArray *neighboringContentMappingURLValue = nil;

@implementation ISAdMobAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return AdMobAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return GADGetStringFromVersionNumber(GADMobileAds.sharedInstance.versionNumber);
}

+ (NSString *)networkAdapterVersion {
    return AdMobAdapterVersion;
}

#pragma mark - Initialization Methods And Callbacks

- (instancetype)init {
    self = [super init];
    if (self) {
        if (initializationDelegates == nil) {
            initializationDelegates = [ISConcurrentMutableSet<ISNetworkInitializationDelegate> set];
        }
    }
    return self;
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    if (initState == INIT_STATE_FAILED) {
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorInternal
                                errorMessage:logInitFailedMessage];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterDelegate_Internal(logCallbackEmpty);

        initState = INIT_STATE_IN_PROGRESS;

        // In case the platform doesn't override this flag the default is to init only the network
        NSString *networkOnlyInitValue = [adData getString:networkOnlyInitKey];
        BOOL networkOnlyInit = networkOnlyInitValue ? [networkOnlyInitValue boolValue] : YES;

        if (networkOnlyInit) {
            [[GADMobileAds sharedInstance] disableMediationInitialization];
        }

        // In case the platform doesn't override this flag the default is not to wait for the init callback before loading an ad
        NSString *initResponseValue = [adData getString:initResponseRequiredKey];
        BOOL shouldWaitForInitCallback = initResponseValue ? [initResponseValue boolValue] : NO;

        if (shouldWaitForInitCallback) {
            ISAdMobAdapter * __weak weakSelf = self;
            [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *_Nonnull status) {
                __typeof__(self) strongSelf = weakSelf;
                NSDictionary *adapterStatuses = status.adapterStatusesByClassName;

                if ([adapterStatuses objectForKey:adMobNetworkId]) {
                    GADAdapterStatus *initStatus = [adapterStatuses objectForKey:adMobNetworkId];
                    if (initStatus.state == GADAdapterInitializationStateReady) {
                        [strongSelf initializationSuccess];
                        return;
                    }
                }

                [strongSelf initializationFailure];
            }];
        } else {
            [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
            [self initializationSuccess];
        }
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(logInitFailed, logInitFailedMessage);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ISAdapterErrorInternal
                                    errorMessage:logInitFailedMessage];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    consentCollectingUserData = consent;
    didSetConsentCollectingUserData = YES;
}

- (void)setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(logCCPA, metaDataCCPAKey, value ? @"YES" : @"NO");
    [NSUserDefaults.standardUserDefaults setBool:value
                                          forKey:metaDataCCPAKey];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }

    if (values.count > 1 && [key caseInsensitiveCompare:metaDataContentMappingKey] == NSOrderedSame) {
        // multiple URL
        neighboringContentMappingURLValue = values;
        LogAdapterApi_Internal(logMetaDataSet, metaDataContentMappingKey, values);
        return;
    }

    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(logMetaDataSet, key, value);

    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
    } else {
        [self setAdMobMetaDataWithKey:[key lowercaseString]
                                value:[value lowercaseString]];
    }
}

- (void)setAdMobMetaDataWithKey:(NSString *)key
                          value:(NSString *)valueString {
    NSString *formattedValueString = valueString;

    if ([key isEqualToString:metaDataTFCDKey] || [key isEqualToString:metaDataTFUAKey]) {
        // Those of the AdMob MetaData keys accept only boolean values
        formattedValueString = [ISMetaDataUtils formatValue:valueString
                                                    forType:(META_DATA_VALUE_BOOL)];

        if (!formattedValueString.length) {
            LogAdapterApi_Internal(logMetaDataSet, key, valueString);
            return;
        }
    }

    if ([key isEqualToString:metaDataTFCDKey]) {
        BOOL coppaValue = [ISMetaDataUtils getMetaDataBooleanValue:formattedValueString];
        LogAdapterApi_Internal(logMetaDataSet, metaDataTFCDKey, coppaValue ? @"YES" : @"NO");
        GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @(coppaValue);
    } else if ([key isEqualToString:metaDataTFUAKey]) {
        BOOL euValue = [ISMetaDataUtils getMetaDataBooleanValue:formattedValueString];
        LogAdapterApi_Internal(logMetaDataSet, metaDataTFUAKey, euValue ? @"YES" : @"NO");
        GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @(euValue);
    } else if ([key isEqualToString:metaDataContentRatingKey]) {
        GADMaxAdContentRating ratingValue = [self getAdMobRatingValue:formattedValueString];
        if (ratingValue.length) {
            LogAdapterApi_Internal(logMetaDataSet, metaDataContentRatingKey, formattedValueString);
            [GADMobileAds.sharedInstance.requestConfiguration setMaxAdContentRating:ratingValue];
        }
    } else if ([key caseInsensitiveCompare:metaDataContentMappingKey] == NSOrderedSame) {
        contentMappingURLValue = valueString;
        LogAdapterApi_Internal(logMetaDataSet, metaDataContentMappingKey, valueString);
    }
}

- (void)setNetworkData:(id<ISAdapterNetworkData>)networkData {
    // If the contentMapping key maps to a string
    NSString *networkDataContentMappingString = [networkData dataByKeyIgnoreCase:networkDataContentMappingKey valueType:[NSString class]];
    if (networkDataContentMappingString != nil) {
        [self processContentMappingString:networkDataContentMappingString];
    }

    // If the contentMapping key maps to an array
    NSArray *networkDataContentMappingArray = [networkData dataByKeyIgnoreCase:networkDataContentMappingKey valueType:[NSArray class]];
    if (networkDataContentMappingArray != nil) {
        [self processContentMappingArray:networkDataContentMappingArray];
    }

    NSString *networkDataContentRating = [networkData dataByKeyIgnoreCase:networkDataContentRatingKey valueType:[NSString class]];
    if (networkDataContentRating != nil) {
        [self processContentRating:[networkDataContentRating lowercaseString]];
    }
}

- (GADMaxAdContentRating)getAdMobRatingValue:(NSString *)value {
    if (!value.length) {
        LogInternal_Error(logRatingValueNil);
        return nil;
    }

    GADMaxAdContentRating contentValue = nil;

    if ([value isEqualToString:maxContentRatingG]) {
        contentValue = GADMaxAdContentRatingGeneral;
    } else if ([value isEqualToString:maxContentRatingPG]) {
        contentValue = GADMaxAdContentRatingParentalGuidance;
    } else if ([value isEqualToString:maxContentRatingT]) {
        contentValue = GADMaxAdContentRatingTeen;
    } else if ([value isEqualToString:maxContentRatingMA]) {
        contentValue = GADMaxAdContentRatingMatureAudience;
    } else {
        LogInternal_Error(logRatingValueUndefined, value);
    }

    return contentValue;
}

- (void)processContentMappingString:(nonnull NSString *)value {
    contentMappingURLValue = value;
    LogAdapterApi_Internal(logMetaDataSet, networkDataContentMappingKey, value);
}

- (void)processContentMappingArray:(nonnull NSArray *)value {
    neighboringContentMappingURLValue = value;
    LogAdapterApi_Internal(logMetaDataSet, networkDataContentMappingKey, value);
}

- (void)processContentRating:(nonnull NSString *)value {
    GADMaxAdContentRating ratingValue = [self getAdMobRatingValue:value];
    if (ratingValue != nil && ratingValue.length) {
        LogAdapterApi_Internal(logMetaDataSet, networkDataContentRatingKey, value);
        [GADMobileAds.sharedInstance.requestConfiguration setMaxAdContentRating:ratingValue];
    }
}

#pragma mark - Adaptive Banner

- (CGFloat)getAdaptiveHeightWithWidth:(CGFloat)width {
    __block GADAdSize adaptiveSize;

    void (^calculateAdaptiveSize)(void) = ^{
        adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width);
    };

    if ([NSThread isMainThread]) {
        calculateAdaptiveSize();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            calculateAdaptiveSize();
        });
    }

    return adaptiveSize.size.height;
}

#pragma mark - Helper Methods

- (NSMutableDictionary *)buildAdditionalParametersWithAdData:(NSDictionary *)adData {
    NSMutableDictionary *additionalParameters = [[NSMutableDictionary alloc] init];

    additionalParameters[platformNameKey] = platformName;
    BOOL hybridMode = NO;

    if (adData) {
        NSString *requestId = [adData objectForKey:adDataRequestIdKey];
        hybridMode = [[adData objectForKey:adDataIsHybridKey] boolValue];

        if (requestId.length) {
            additionalParameters[placementRequestIdKey] = requestId;
        }
    }

    additionalParameters[isHybridSetupKey] = hybridMode ? isHybridSetupTrueValue : isHybridSetupFalseValue;

    if (didSetConsentCollectingUserData && !consentCollectingUserData) {
        // The default behavior of the Google Mobile Ads SDK is to serve personalized ads.
        // If a user has consented to receive only non-personalized ads, configure the request
        // to specify that only non-personalized ads should be returned.
        additionalParameters[nonPersonalizedAdsKey] = nonPersonalizedAdsValue;
    }

    return additionalParameters;
}

- (void)setChildDirectedTreatmentIfNeeded {
    if ([ISConfigurations getConfigurations].userAge > minUserAge) {
        BOOL tagForChildDirectedTreatment = [ISConfigurations getConfigurations].userAge < maxChildAge;
        GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @(tagForChildDirectedTreatment);
    }
}

- (void)applyContentMappingToRequest:(GADRequest *)request {
    if (contentMappingURLValue.length) {
        request.contentURL = contentMappingURLValue;
    }

    if (neighboringContentMappingURLValue.count) {
        request.neighboringContentURLStrings = neighboringContentMappingURLValue;
    }
}

- (void)applyContentMappingToSignalRequest:(GADSignalRequest *)request {
    if (contentMappingURLValue.length) {
        request.contentURL = contentMappingURLValue;
    }

    if (neighboringContentMappingURLValue.count) {
        request.neighboringContentURLStrings = neighboringContentMappingURLValue;
    }
}

- (GADRequest *)createGADRequestWithAdData:(NSDictionary *)adData {
    GADRequest *request = [GADRequest request];
    request.requestAgent = requestAgent;

    NSMutableDictionary *additionalParameters = [self buildAdditionalParametersWithAdData:adData];

    [self setChildDirectedTreatmentIfNeeded];
    [self applyContentMappingToRequest:request];

    GADExtras *extras = [[GADExtras alloc] init];
    extras.additionalParameters = additionalParameters;
    [request registerAdNetworkExtras:extras];

    return request;
}

- (void)collectBiddingDataWithSignalRequest:(GADSignalRequest *)request
                                     adData:(ISAdData *)adData
                                   delegate:(id<ISBiddingDataDelegate>)delegate {
    // Token Fetch Time = "Init Started": tokens can be collected once init has started
    if (initState == INIT_STATE_NONE) {
        LogAdapterApi_Internal(logError, logTokenInitNotStarted);
        [delegate failureWithError:logTokenInitNotStarted];
        return;
    }

    if (!request) {
        LogAdapterApi_Internal(logError, logSignalFailed);
        [delegate failureWithError:logSignalFailed];
        return;
    }

    request.requestAgent = requestAgent;

    NSString *adUnitId = [adData getString:adUnitIdKey];
    if (adUnitId.length) {
        request.adUnitID = adUnitId;
        LogAdapterApi_Internal(logAdUnitId, adUnitId);
    }

    NSMutableDictionary *additionalParameters = [self buildAdditionalParametersWithAdData:adData.adUnitData];
    additionalParameters[queryInfoTypeKey] = requesterType;

    [self setChildDirectedTreatmentIfNeeded];
    [self applyContentMappingToSignalRequest:request];

    GADExtras *gadExtras = [[GADExtras alloc] init];
    gadExtras.additionalParameters = additionalParameters;
    [request registerAdNetworkExtras:gadExtras];

    NSString *sdkVersion = [self networkSDKVersion];
    [GADMobileAds generateSignal:request
               completionHandler:^(GADSignal *_Nullable signal, NSError *_Nullable error) {
        if (error) {
            LogAdapterApi_Internal(logError, error.localizedDescription);
            [delegate failureWithError:error.localizedDescription];
            return;
        }

        if (!signal) {
            LogAdapterApi_Internal(logError, logSignalNil);
            [delegate failureWithError:logSignalNil];
            return;
        }

        NSString *returnedToken = signal.signalString ? signal.signalString : @"";
        LogAdapterApi_Internal(logToken, returnedToken, sdkVersion);
        NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken, sdkVersionKey: sdkVersion};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
