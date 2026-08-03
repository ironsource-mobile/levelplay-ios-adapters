//
//  ISVungleAdapter.m
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISVungleAdapter.h"
#import "ISVungleAdapter+Internal.h"
#import "ISVungleConstants.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISVungleAdapter ()

@end

@implementation ISVungleAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return VungleAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [VungleAds sdkVersion];
}

+ (NSString *)networkAdapterVersion {
    return VungleAdapterVersion;
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

    if (!appId || appId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appIdKey];
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

        LogAdapterApi_Internal(logAppId, appId);

        dispatch_async(dispatch_get_main_queue(), ^{
            [VungleAds setIntegrationName:mediationName
                                  version:[self adapterVersion]];

            ISVungleAdapter * __weak weakSelf = self;
            [VungleAds initWithAppId:appId
                          completion:^(NSError * _Nullable error) {
                __typeof__(self) strongSelf = weakSelf;
                if (error) {
                    NSString *errorMessage = [NSString stringWithFormat:logInitFailedWithError, error.description];
                    [strongSelf initializationFailure:errorMessage];
                } else {
                    [strongSelf initializationSuccess];
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
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    [VunglePrivacySettings setGDPRStatus:consent];
    [VunglePrivacySettings setGDPRMessageVersion:@""];
}

- (void)setCCPAValue:(BOOL)value {
    // The Vungle CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the LevelPlay Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    LogAdapterApi_Internal(logCCPA, optIn ? @"YES" : @"NO");
    [VunglePrivacySettings setCCPAStatus:optIn];
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(logCOPPA, value ? @"YES" : @"NO");
    [VunglePrivacySettings setCOPPAStatus:value];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState == INIT_STATE_FAILED) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *bidderToken = [VungleAds getBiddingToken];
    NSString *returnedToken = bidderToken ? bidderToken : @"";
    LogAdapterApi_Internal(logToken, returnedToken);

    NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
    [delegate successWithBiddingData:biddingDataDictionary];
}

@end
