//
//  ISMobileFuseAdapter.m
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//
#import <MobileFuseSDK/MobileFuse.h>
#import <MobileFuseSDK/MobileFuseSettings.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>
#import <MobileFuseSDK/MFBiddingTokenProvider.h>
#import <MobileFuseSDK/MobileFusePrivacyPreferences.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import "ISMobileFuseAdapter.h"
#import "ISMobileFuseConstants.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

// Privacy default values
static BOOL coppaValue = NO;
static BOOL doNotTrackValue = NO;
static NSString *doNotSellValue = metaDataCCPADefaultValue;

@interface ISMobileFuseAdapter() <IMFInitializationCallbackReceiver>

@end

@implementation ISMobileFuseAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return mobileFuseAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [MobileFuse version];
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
    if (initState == INIT_STATE_SUCCESS && delegate) {
        [delegate onInitDidSucceed];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    NSString *placementId = [adData getString:placementIdKey];

    // Configuration Validation
    if (!placementId || placementId.length == 0) {
        LogAdapterApi_Internal(logError, logMissingPlacementId);
        if (delegate) {
            [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:logMissingPlacementId];
        }
        return;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterApi_Internal(logPlacementId, placementId);

        if ([MobileFuseSettings respondsToSelector:@selector(setSdkAdapter:)]) {
            [MobileFuseSettings setSdkAdapter:mediationName];
        }
        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [MobileFuse enableVerboseLogging];
        }
        [MobileFuse initWithDelegate:self];
    });
}

- (void)onInitSuccess:(NSString *)appId withPublisherId:(NSString *)publisherId {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)onInitError:(NSString *)appId withPublisherId:(NSString *)publisherId withError:(MFAdError *)error {
    LogAdapterDelegate_Internal(logError, error.description);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidFailWithErrorCode:error.code errorMessage:error.description];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }

    NSString *value = values[0];
    LogAdapterApi_Internal(logMetaDataSet, key, value);

    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];

    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];

        if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                               flag:metaDataCOPPAKey
                                           andValue:formattedValue]) {
            [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
        }
    }
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    doNotTrackValue = consent ? NO : YES; // doNotTrack is opposite of consent
}

- (void)setCCPAValue:(BOOL)doNotSell {
    LogAdapterApi_Internal(logCCPA, doNotSell ? @"YES" : @"NO");
    doNotSellValue = doNotSell ? metaDataCCPANoConsentValue : metaDataCCPAConsentValue;
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(logCOPPA, value ? @"YES" : @"NO");
    coppaValue = value;
}

#pragma mark - Helper Methods

- (MobileFusePrivacyPreferences *)getPrivacyData {
    MobileFusePrivacyPreferences *privacyPreferences = [[MobileFusePrivacyPreferences alloc] init];
    [privacyPreferences setSubjectToCoppa:coppaValue];
    [privacyPreferences setDoNotTrack:doNotTrackValue];
    [privacyPreferences setUsPrivacyConsentString:doNotSellValue];
    return privacyPreferences;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {

    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    MFBiddingTokenRequest *request = [[MFBiddingTokenRequest alloc] init];
    request.privacyPreferences = [self getPrivacyData];

    [MFBiddingTokenProvider getTokenWithRequest:request withCallback:^(NSString *token) {
        if (token == nil || token.length == 0) {
            [delegate failureWithError:logTokenFailed];
            return;
        }

        LogAdapterApi_Internal(logToken, token);
        NSDictionary *biddingDataDictionary = @{tokenKey: token};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
