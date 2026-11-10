//
//  ISFyberAdapter.m
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IASDKCore/IASDKCore.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISError.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISFyberAdapter.h"
#import "ISFyberAdapter+Internal.h"
#import "ISFyberConstants.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

static NSNumber *consentCollectingUserData = nil;
static NSNumber *ccpaCollectingUserData = nil;
static NSNumber *coppaCollectingUserData = nil;

@interface ISFyberAdapter ()

@end

@implementation ISFyberAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return FyberAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [[IASDKCore sharedInstance] version];
}

+ (NSString *)networkAdapterVersion {
    return FyberAdapterVersion;
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
    NSString *spotId = [adData getString:spotIdKey];

    if (!appId || appId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!spotId || spotId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, spotIdKey];
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
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterApi_Internal(logInitAppId, appId);

        [[IASDKCore sharedInstance] initWithAppID:appId
                                  completionBlock:^(BOOL success, NSError *_Nullable error) {
            if (success) {
                [self initializationSuccess];
            } else {
                NSString *errorMessage = [NSString stringWithFormat:logInitFailedWithError, error.description];
                [self initializationFailure:errorMessage];
            }
        }
                                  completionQueue:dispatch_get_main_queue()];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    if (consentCollectingUserData != nil) {
        [self setConsent:[consentCollectingUserData boolValue]];
    }

    if (ccpaCollectingUserData != nil) {
        [self setCCPAValue:[ccpaCollectingUserData boolValue]];
    }

    if (coppaCollectingUserData != nil) {
        [self setCOPPAValue:[coppaCollectingUserData boolValue]];
    }

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)initializationFailure:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(logError, errorMessage);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");

    if (initState == INIT_STATE_SUCCESS) {
        [IASDKCore.sharedInstance setGDPRConsent:consent];
    } else {
        consentCollectingUserData = @(consent);
    }
}

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

- (void)setCCPAValue:(BOOL)doNotSell {
    LogAdapterApi_Internal(logCCPA, doNotSell ? @"YES" : @"NO");

    if (initState == INIT_STATE_SUCCESS) {
        NSString *ccpaString = doNotSell ? ccpaDoNotSellString : ccpaConsentString;
        [IASDKCore.sharedInstance setCCPAString:ccpaString];
    } else {
        ccpaCollectingUserData = @(doNotSell);
    }
}

- (void)setCOPPAValue:(BOOL)isChildDirected {
    LogAdapterApi_Internal(logCOPPA, isChildDirected ? @"YES" : @"NO");

    if (initState == INIT_STATE_SUCCESS) {
        IASDKCore.sharedInstance.coppaApplies =
            isChildDirected ? IACoppaAppliesTypeTrue : IACoppaAppliesTypeFalse;
    } else {
        coppaCollectingUserData = @(isChildDirected);
    }
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *token = [[FMPBiddingManager sharedInstance] biddingToken];
    NSString *returnedToken = token ? token : @"";
    LogAdapterApi_Internal(logToken, returnedToken);

    NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
    [delegate successWithBiddingData:biddingDataDictionary];
}

@end
