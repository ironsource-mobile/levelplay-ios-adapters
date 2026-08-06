//
//  ISVoodooAdapter.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISVoodooAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@implementation ISVoodooAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return VoodooAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [AdnSdkBridge sdkVersion];
}

+ (NSString *)networkAdapterVersion {
    return VoodooAdapterVersion;
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
    NSString *placementId = [adData getString:placementIdKey];

    // Configuration Validation
    if (!placementId || placementId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    if (initState == INIT_STATE_FAILED) {
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:logInitFailed];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(logPlacementId, placementId);

        initState = INIT_STATE_IN_PROGRESS;

        ISVoodooAdapter * __weak weakSelf = self;
        [AdnSdkBridge initializeWith:mediationName
                          completion:^(bool success) {
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

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(logInitFailed);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED
                                    errorMessage:logInitFailed];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                         placementType:(AdnPlacementType)placementType {
    if (initState == INIT_STATE_NONE) {
        LogAdapterApi_Internal(logError, logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    [AdnSdkBridge getBidTokenWithPlacement:placementType
                                completion:^(NSString *token) {
        if (token.length == 0) {
            LogAdapterApi_Internal(logError, logTokenFailed);
            [delegate failureWithError:logTokenFailed];
            return;
        }

        NSString *sdkVersion = [AdnSdkBridge sdkVersion];
        LogAdapterApi_Internal(logToken, token, sdkVersion);
        [delegate successWithBiddingData:@{tokenKey: token, sdkVersionKey: sdkVersion}];
    }];
}

@end
