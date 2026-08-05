//
//  ISChartboostAdapter.m
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISChartboostAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

static CHBMediation *mediationInfo = nil;
static NSNumber *setCOPPA = nil;

@implementation ISChartboostAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return ChartboostAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [Chartboost getSDKVersion];
}

+ (NSString *)networkAdapterVersion {
    return ChartboostAdapterVersion;
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
    NSString *appId = [adData getString:appIdKey];
    NSString *appSignature = [adData getString:appSignatureKey];

    // Configuration Validation
    if (!appId || appId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!appSignature || appSignature.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appSignatureKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    if (initState == INIT_STATE_FAILED) {
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:logInitFailedMessage];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterApi_Internal(logAppIdAndAppSignature, appId, appSignature);

        CBLoggingLevel logLevel = ([ISConfigurations getConfigurations].adaptersDebug) ? CBLoggingLevelVerbose : CBLoggingLevelError;
        [Chartboost setLoggingLevel:logLevel];

        ISChartboostAdapter * __weak weakSelf = self;
        [Chartboost startWithAppID:appId
                      appSignature:appSignature
                        completion:^(CHBStartError * _Nullable error) {
            __typeof__(self) strongSelf = weakSelf;
            if (error) {
                [strongSelf initializationFailureWithError:error.description];
            } else {
                [strongSelf initializationSuccess];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    // Chartboost only accepts the COPPA flag once its SDK has started
    if (setCOPPA != nil) {
        [self setCOPPAValue:[setCOPPA boolValue]];
    }

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)initializationFailureWithError:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(logInitFailed, errorMessage);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED
                                    errorMessage:logInitFailedMessage];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }

    // this is a list of 1 value
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
    [Chartboost addDataUseConsent:[CHBGDPRDataUseConsent gdprConsent:(consent ? CHBGDPRConsentBehavioral : CHBGDPRConsentNonBehavioral)]];
}

- (void)setCCPAValue:(BOOL)ccpa {
    LogAdapterApi_Internal(logCCPA, ccpa ? @"YES" : @"NO");
    [Chartboost addDataUseConsent:[CHBCCPADataUseConsent ccpaConsent:(ccpa ? CHBCCPAConsentOptOutSale : CHBCCPAConsentOptInSale)]];
}

- (void)setCOPPAValue:(BOOL)coppa {
    setCOPPA = @(coppa);
    LogAdapterApi_Internal(logCOPPA, coppa ? @"YES" : @"NO");

    if (initState == INIT_STATE_SUCCESS) {
        [Chartboost addDataUseConsent:[CHBCOPPADataUseConsent isChildDirected:coppa]];
    }
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *bidderToken = [Chartboost bidderToken];
    NSString *returnedToken = bidderToken ? bidderToken : @"";
    LogAdapterApi_Internal(logToken, returnedToken);
    [delegate successWithBiddingData:@{tokenKey: returnedToken}];
}

- (CHBMediation *)getMediationInfo {
    if (mediationInfo == nil) {
        mediationInfo = [[CHBMediation alloc] initWithName:mediationName
                                            libraryVersion:[LevelPlay sdkVersion]
                                            adapterVersion:ChartboostAdapterVersion];
    }

    return mediationInfo;
}

@end
