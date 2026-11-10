//
//  ISMolocoAdapter.m
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import <MolocoSDK/MolocoSDK-Swift.h>
#import "ISMolocoAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initCallbackDelegates = nil;

@implementation ISMolocoAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return MolocoAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return Moloco.shared.sdkVersion;
}

+ (NSString *)networkAdapterVersion {
    return MolocoAdapterVersion;
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
    NSString *appKey = [adData getString:appKeyKey];
    NSString *adUnitId = [adData getString:adUnitIdKey];

    if (!appKey || appKey.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appKeyKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    if (initState == INIT_STATE_FAILED) {
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorInternal errorMessage:logInitFailed];
        return;
    }

    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initCallbackDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterApi_Internal(logAppKeyAndAdUnitId, appKey, adUnitId);

        initState = INIT_STATE_IN_PROGRESS;

        MolocoInitParams *initParams = [[MolocoInitParams alloc] initWithAppKey:appKey
                                                                       mediation:mediationName];
        __weak typeof(self) weakSelf = self;
        [[Moloco shared] initializeWithParams:initParams
                                   completion:^(BOOL success, NSError * _Nullable error) {
            __typeof__(self) strongSelf = weakSelf;
            if (success) {
                [strongSelf initializationSuccess];
            } else {
                [strongSelf initializationFailure];
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
    LogAdapterDelegate_Internal(logInitFailed);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ISAdapterErrorInternal
                                     errorMessage:logInitFailed];
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

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    MolocoPrivacySettings.hasUserConsent = consent;
}

- (void)setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(logCCPA, value ? @"YES" : @"NO");
    MolocoPrivacySettings.isDoNotSell = value;
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(logCOPPA, value ? @"YES" : @"NO");
    MolocoPrivacySettings.isAgeRestrictedUser = value;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    // Token Fetch Time: "After Init Success" - check initState == INIT_STATE_SUCCESS
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    MolocoParams *params = [[MolocoParams alloc] initWithMediation:mediationName];
    [Moloco.shared getBidTokenWithParams:params completion:^(NSString *token, NSError *error) {
        if (error) {
            LogAdapterApi_Internal(logError, error.localizedDescription);
            [delegate failureWithError:error.localizedDescription];
            return;
        }

        NSString *returnedToken = token ? token : @"";
        LogAdapterApi_Internal(logToken, returnedToken);
        NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
