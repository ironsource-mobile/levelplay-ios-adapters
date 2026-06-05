//
//  ISVerveAdapter.m
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISVerveAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initCallbackDelegates = nil;

@interface ISVerveAdapter ()

@end

@implementation ISVerveAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return VerveAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return HyBid.sdkVersion;
}

#pragma mark - Initialization Methods And Callbacks

- (instancetype)init {
    self = [super init];
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitializationDelegate> set];
        }
    }
    return self;
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    NSString *appToken = [adData getString:appTokenKey];
    NSString *zoneId = [adData getString:zoneIdKey];

    // Configuration Validation
    if (!appToken || appToken.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appTokenKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!zoneId || zoneId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, zoneIdKey];
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
        [initCallbackDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterDelegate_Internal(logAppTokenAndZoneId, appToken, zoneId);

        BOOL enableLogs = [ISConfigurations getConfigurations].adaptersDebug;
        if (enableLogs) {
            [HyBidLogger setLogLevel:HyBidLogLevelDebug];
        }

        [HyBid initWithAppToken:appToken
                     completion:^(BOOL initSuccess) {
            if (initSuccess) {
                [self initializationSuccess];
            } else {
                [self initializationFailure];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(logInitFailedMessage);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED
                                     errorMessage:logInitFailedMessage];
    }

    [initCallbackDelegates removeAllObjects];
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

- (void)setCCPAValue:(BOOL)ccpa {
    NSString *ccpaConsentString = ccpa ? metaDataCCPAConsentValue : metaDataCCPANoConsentValue;
    LogAdapterApi_Internal(logCCPA, ccpaConsentString);
    [[HyBidUserDataManager sharedInstance] setIABUSPrivacyString:ccpaConsentString];
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(logCOPPA, value ? @"YES" : @"NO");
    [HyBid setCoppa:value];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *signal = [HyBid getCustomRequestSignalData:mediationName];
    if (signal.length) {
        LogAdapterApi_Internal(logToken, signal);
        [delegate successWithBiddingData:@{tokenKey: signal}];
    } else {
        LogAdapterApi_Internal(logTokenFailed);
        [delegate failureWithError:logTokenFailed];
    }
}

@end
