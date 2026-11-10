//
//  ISLineAdapter.m
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISLineAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

static FADAdLoader *lineAdLoader = nil;

@implementation ISLineAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return LineAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [FADAdLoader semanticVersion];
}

+ (NSString *)networkAdapterVersion {
    return LineAdapterVersion;
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

        LogAdapterApi_Internal(logAppIdAndSlotId, appId, slotId);

        if ([self getAdLoader:appId]) {
            [self initializationSuccess];
        } else {
            [self initializationFailure];
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

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                                 appId:(NSString *)appId
                                slotId:(NSString *)slotId {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logError, logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    FADAdLoader *adLoader = [self getAdLoader:appId];

    if (adLoader == nil) {
        LogAdapterApi_Internal(logError, logAdLoaderNil);
        [delegate failureWithError:logAdLoaderNil];
        return;
    }

    [adLoader collectSignalWithSlotId:slotId
                   withSignalCallback:^(NSString *_Nullable signal, NSError *_Nullable error) {
        if (error != nil) {
            LogAdapterApi_Internal(logError, error.localizedDescription);
            [delegate failureWithError:error.localizedDescription];
            return;
        }

        if (signal.length == 0) {
            LogAdapterApi_Internal(logError, logTokenFailed);
            [delegate failureWithError:logTokenFailed];
            return;
        }

        LogAdapterApi_Internal(logToken, signal);
        [delegate successWithBiddingData:@{tokenKey: signal}];
    }];
}

- (FADAdLoader *)getAdLoader:(NSString *)appId {
    if (!lineAdLoader) {
        NSError *error = nil;
        FADConfig *config = [[FADConfig alloc] initWithAppId:appId];
        lineAdLoader = [FADAdLoader adLoaderForConfig:config outError:&error];

        if (error) {
            LogAdapterApi_Internal(logError, error.localizedDescription);
            lineAdLoader = nil;
        }
    }

    return lineAdLoader;
}

@end
