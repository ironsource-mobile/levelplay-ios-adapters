//
//  ISMintegralAdapter.m
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISMintegralAdapter.h"
#import "ISMintegralAdapter+Internal.h"
#import "ISMintegralConstants.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

static NSNumber *consentCollectingUserData = nil;
static NSNumber *doNotSellCollectingUserData = nil;
static BOOL coppaCollectingUserData = NO;

@interface ISMintegralAdapter ()

@end

@implementation ISMintegralAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return MintegralAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [MTGSDK sdkVersion];
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
    NSString *appKey = [adData getString:appKeyKey];
    NSString *placementId = [adData getString:placementIdKey];

    if (!appId || appId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!appKey || appKey.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appKeyKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

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

    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            initState = INIT_STATE_IN_PROGRESS;

            LogAdapterApi_Internal(logAppIdAndAppKey, appId, appKey);

            if (consentCollectingUserData != nil) {
                [self setConsent:[consentCollectingUserData boolValue]];
            }

            if (doNotSellCollectingUserData != nil) {
                [self setCCPAValue:[doNotSellCollectingUserData boolValue]];
            }

            MTGSDK *mtgSDK = [MTGSDK sharedInstance];
            [self setChannelCode:mtgSDK];
            [mtgSDK initializeWithAppID:appId
                                 ApiKey:appKey
                      completionHandler:^(BOOL success, NSError *_Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [self initializationSuccess];
                    } else {
                        NSString *errorMessage = [NSString stringWithFormat:logInitFailedWithError, error.description];
                        [self initializationFailure:errorMessage];
                    }
                });
            }];
        });
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    [self setCOPPAValue:coppaCollectingUserData];

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
    switch (initState) {
        case INIT_STATE_NONE:
            consentCollectingUserData = @(consent);
            break;
        case INIT_STATE_IN_PROGRESS:
            LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
            [[MTGSDK sharedInstance] setConsentStatus:consent];
            break;
        case INIT_STATE_SUCCESS:
        case INIT_STATE_FAILED:
            break;
    }
}

- (void)setCCPAValue:(BOOL)doNotSell {
    switch (initState) {
        case INIT_STATE_NONE:
            doNotSellCollectingUserData = @(doNotSell);
            break;
        case INIT_STATE_IN_PROGRESS:
            LogAdapterApi_Internal(logCCPA, doNotSell ? @"YES" : @"NO");
            [[MTGSDK sharedInstance] setDoNotTrackStatus:doNotSell];
            break;
        case INIT_STATE_SUCCESS:
        case INIT_STATE_FAILED:
            break;
    }
}

- (void)setCOPPAValue:(BOOL)isChildDirected {
    LogAdapterApi_Internal(logCOPPA, isChildDirected ? @"YES" : @"NO");

    if (!isChildDirected) {
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [[MTGSDK sharedInstance] setCoppa:MTGBoolYes];
    } else {
        coppaCollectingUserData = MTGBoolYes;
    }
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithPlacementId:(NSString *)placementId
                                   unitId:(NSString *)unitId
                                   adType:(MintegralAdType)adType
                                 delegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSDictionary *adConfig = @{placementIdKey: placementId ?: @"",
                               unitIdKey: unitId ?: @"",
                               adTypeKey: @(adType)};

    NSString *token = [MTGBiddingSDK buyerUIDWithDictionary:adConfig];
    NSString *returnedToken = token ? token : @"";
    LogAdapterApi_Internal(logToken, returnedToken);

    NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
    [delegate successWithBiddingData:biddingDataDictionary];
}

- (void)setChannelCode:(MTGSDK *)mtgSDK {
    @try {
        Class mintegralClass = NSClassFromString(channelClassName);
        SEL setChannelSelector = NSSelectorFromString(channelSelectorName);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

        if ([mintegralClass respondsToSelector:setChannelSelector]) {
            [mintegralClass performSelector:setChannelSelector withObject:channelCode];
        }

#pragma clang diagnostic pop

    } @catch (NSException *exception) {
        LogInternal_Error(logChannelCodeFailed, exception);
    }
}

@end
