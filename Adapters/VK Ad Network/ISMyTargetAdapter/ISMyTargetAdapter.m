//
//  ISMyTargetAdapter.m
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISMyTargetAdapter.h"
#import "ISMyTargetAdapter+Internal.h"
#import "ISMyTargetConstants.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISMyTargetAdapter ()

@end

@implementation ISMyTargetAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return MyTargetAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [MTRGVersion currentVersion];
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
    NSString *slotId = [adData getString:slotIdKey];

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

    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterApi_Internal(logSlotId, slotId);

        initState = INIT_STATE_IN_PROGRESS;

        [MTRGManager setDebugMode:[ISConfigurations getConfigurations].adaptersDebug];
        [MTRGManager initSdk];

        [self initializationSuccess];
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

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    [MTRGPrivacy setUserConsent:consent];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *token = [MTRGManager getBidderToken];
    NSString *returnedToken = token ? token : @"";
    LogAdapterApi_Internal(logToken, returnedToken);

    NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
    [delegate successWithBiddingData:biddingDataDictionary];
}

@end
