//
//  ISYSOAdapter.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISYSOAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@implementation ISYSOAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return YSOAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [YsoNetwork getSdkVersion];
}

+ (NSString *)networkAdapterVersion {
    return YSOAdapterVersion;
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
    NSString *placementKey = [adData getString:placementKeyKey];

    // Configuration Validation
    if (!placementKey || placementKey.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementKeyKey];
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

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterApi_Internal(logPlacementKey, placementKey);

        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                [YsoNetwork initializeSdk];

                if ([YsoNetwork isInitialized]) {
                    [self initializationSuccess];
                } else {
                    [self initializationFailure];
                }
            }
            @catch (NSException *exception) {
                LogAdapterApi_Internal(logInitException, exception.reason);
                [self initializationFailure];
            }
        });
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
    LogAdapterDelegate_Internal(logInitFailedMessage);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED
                                    errorMessage:logInitFailedMessage];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Helper Methods

+ (NSString *)loadErrorToString:(e_ActionError)error {
    switch (error) {
        case e_ActionErrorSdkNotInitialized:
            return errorSdkNotInitialized;
        case e_ActionErrorInvalidRequest:
            return errorInvalidRequest;
        case e_ActionErrorInvalidConfig:
            return errorInvalidConfig;
        case e_ActionErrorLoad:
            return errorLoad;
        case e_ActionErrorTimeout:
            return errorTimeout;
        case e_ActionErrorServer:
            return errorServer;
        case e_ActionErrorInternal:
            return errorInternal;
        default:
            return errorUnknown;
    }
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logError, logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *token = [YsoNetwork getSignal];

    if (!token.length) {
        LogAdapterApi_Internal(logError, logTokenFailed);
        [delegate failureWithError:logTokenFailed];
        return;
    }

    NSString *sdkVersion = [YsoNetwork getSdkVersion];
    LogAdapterApi_Internal(logToken, token, sdkVersion);
    [delegate successWithBiddingData:@{tokenKey: token, sdkVersionKey: sdkVersion}];
}

@end
