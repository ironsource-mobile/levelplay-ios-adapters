//
//  ISBigoAdapter.m
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BigoADS/BigoAdSdk.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISBigoAdapter.h"
#import "ISBigoConstants.h"

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISBigoAdapter ()

@end

@implementation ISBigoAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return BigoAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return BigoAdSdk.sharedInstance.getSDKVersionName;
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

    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterDelegate_Internal(logAppIdAndSlotId, appId, slotId);

        BigoAdConfig *adConfig = [[BigoAdConfig alloc] initWithAppId:appId];
        [[BigoAdSdk sharedInstance] initializeSdkWithAdConfig:adConfig completion:^{
            [self initializationSuccess];
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
    [BigoAdSdk setUserConsentWithOption:BigoConsentOptionsGDPR consent:consent];
}

- (void)setCCPAValue:(BOOL)doNotSell {
    LogAdapterApi_Internal(logCCPA, doNotSell ? @"YES" : @"NO");
    [BigoAdSdk setUserConsentWithOption:BigoConsentOptionsCCPA consent:!doNotSell];
}

- (void)setCOPPAValue:(BOOL)childRestricted {
    LogAdapterApi_Internal(logCOPPA, childRestricted ? @"YES" : @"NO");
    [BigoAdSdk setUserConsentWithOption:BigoConsentOptionsCOPPA consent:!childRestricted];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *bidderToken = [[BigoAdSdk sharedInstance] getBidderToken];
    if (!bidderToken || bidderToken.length == 0) {
        LogAdapterApi_Internal(logTokenFailed);
        [delegate failureWithError:logTokenFailed];
        return;
    }

    LogAdapterApi_Internal(logToken, bidderToken);
    NSDictionary *biddingDataDictionary = @{tokenKey: bidderToken};
    [delegate successWithBiddingData:biddingDataDictionary];
}

- (NSString *)getMediationInfo {
    NSDictionary *mediationInfoDict = @{
        mediationNameKey: mediationName,
        mediationVersionKey: [LevelPlay sdkVersion],
        adapterVersionKey: BigoAdapterVersion
    };

    NSError *error = nil;
    NSData *mediationInfoJSONData = [NSJSONSerialization dataWithJSONObject:mediationInfoDict
                                                                    options:0
                                                                      error:&error];

    if (!error) {
        return [[NSString alloc] initWithData:mediationInfoJSONData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end
