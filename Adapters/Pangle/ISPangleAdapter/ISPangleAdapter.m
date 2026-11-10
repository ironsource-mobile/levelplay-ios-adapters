//
//  ISPangleAdapter.m
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISPangleAdapter.h"
#import "ISPangleConstants.h"

static InitState initState = INIT_STATE_NONE;
static NSInteger childDirected = pangleChildDirectedTypeDefault;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISPangleAdapter ()

@end

@implementation ISPangleAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return PangleAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [PAGSdk SDKVersion];
}

+ (NSString *)networkAdapterVersion {
    return PangleAdapterVersion;
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
    NSString *slotId = [adData getString:slotIdKey];

    // Configuration Validation
    if (!appId || appId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!slotId || slotId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, slotIdKey];
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
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterDelegate_Internal(logAppIdAndSlotId, appId, slotId);

        initState = INIT_STATE_IN_PROGRESS;

        if ([self isCoppaChildUser]) {
            [self initializationFailure:[self childError].description];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            PAGConfig *config = [PAGConfig shareConfig];
            config.userDataString = [NSString stringWithFormat: @"[{\"name\":\"mediation\",\"value\":\"Ironsource\"},{\"name\":\"adapter_version\",\"value\":\"%@\"}]", self.adapterVersion];
            config.appID = appId;
            config.debugLog = [ISConfigurations getConfigurations].adaptersDebug ? YES : NO;
            config.adxID = levelPlayAdxId;

            __weak ISPangleAdapter *weakSelf = self;
            [PAGSdk startWithConfig:config
                  completionHandler:^(BOOL success, NSError *error) {
                __typeof__(self) strongSelf = weakSelf;
                if (success) {
                    [strongSelf initializationSuccess];
                } else {
                    NSString *errorMsg = error ? [NSString stringWithFormat:logInitError, error.description] : [NSString stringWithFormat:logInitError, @""];
                    [strongSelf initializationFailure:errorMsg];
                }
            }];
        });
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)initializationFailure:(NSString *)error {
    LogAdapterDelegate_Internal(logError, error);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorInternal errorMessage:error];
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

    } else if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                                 flag:metaDataCOPPAKey
                                             andValue:value]) {
        [self setCOPPAValue:value];
    }
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logGDPRError);
}

- (void)setCCPAValue:(BOOL)ccpa {
    NSString *ccpaConsentLog = ccpa ? logConsentTypeNoConsent : logConsentTypeConsent;
    LogAdapterApi_Internal(logCCPA, ccpaConsentLog);

    PAGConfig *config = [PAGConfig shareConfig];
    config.PAConsent = ccpa ? PAGPAConsentTypeNoConsent : PAGPAConsentTypeConsent;
}

- (void)setCOPPAValue:(NSString *)value {
    NSString *coppaValueString;

    if (value.integerValue == pangleChildDirectedTypeChild) {
        childDirected = pangleChildDirectedTypeChild;
        coppaValueString = logChildTypeChild;
    }
    else if (value.integerValue == pangleChildDirectedTypeNonChild) {
        childDirected = pangleChildDirectedTypeNonChild;
        coppaValueString = logChildTypeNonChild;
    }
    else {
        childDirected = pangleChildDirectedTypeDefault;
        coppaValueString = logChildTypeDefault;
    }

    LogAdapterApi_Internal(logCOPPA, coppaValueString);
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithSlotId:(NSString *)slotId
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    if ([self isCoppaChildUser]) {
        NSError *error = [self childError];
        LogAdapterApi_Internal(logError, error);
        [delegate failureWithError:error.description];
        return;
    }

    PAGBiddingRequest *request = [PAGBiddingRequest new];
    request.adxID = levelPlayAdxId;
    request.slotID = slotId;

    [PAGSdk getBiddingTokenWithRequest:request
                    completionHandler:^(NSString * _Nullable biddingToken, NSError * _Nullable error) {
        if (biddingToken.length > 0) {
            LogAdapterApi_Internal(logToken, biddingToken);
            NSDictionary *biddingDataDictionary = @{tokenKey: biddingToken};
            [delegate successWithBiddingData:biddingDataDictionary];
        } else {
            NSString *errorMsg = error.description ?: logTokenFailed;
            LogAdapterApi_Internal(logError, errorMsg);
            [delegate failureWithError:errorMsg];
        }
    }];
}

- (BOOL)isCoppaChildUser {
    return childDirected == pangleChildDirectedTypeChild;
}

- (NSError *)childError {
    return [NSError errorWithDomain:networkName
                               code:pangleChildErrorCode
                           userInfo:@{NSLocalizedDescriptionKey:logChildError}];
}

@end
