//
//  ISOguryAdapter.m
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>
#import <OguryCore/OguryLogLevel.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISOguryAdapter.h"
#import "ISOguryAdapter+Internal.h"
#import "ISOguryConstants.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISOguryAdapter ()

@end

@implementation ISOguryAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return OguryAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [Ogury sdkVersion];
}

+ (NSString *)networkAdapterVersion {
    return OguryAdapterVersion;
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
    NSString *assetKey = [adData getString:assetKeyKey];
    NSString *adUnitId = [adData getString:adUnitIdKey];

    if (!assetKey || assetKey.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, assetKeyKey];
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
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:logInitFailed];
        return;
    }

    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterApi_Internal(logAssetKeyAndAdUnitId, assetKey, adUnitId);

        initState = INIT_STATE_IN_PROGRESS;

        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [Ogury setLogLevel:OguryLogLevelAll];
        }

        [Ogury startWith:assetKey completionHandler:^(BOOL success, OguryError *_Nullable error) {
            if (success) {
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

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(logInitFailed);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:logInitFailed];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    [OguryBidTokenService bidToken:^(NSString *_Nullable signal, OguryError *_Nullable error) {
        if (error) {
            LogAdapterApi_Internal(logTokenFailed);
            [delegate failureWithError:logTokenFailed];
            return;
        }

        NSString *returnedToken = signal ? signal : @"";
        LogAdapterApi_Internal(logToken, returnedToken);
        NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
