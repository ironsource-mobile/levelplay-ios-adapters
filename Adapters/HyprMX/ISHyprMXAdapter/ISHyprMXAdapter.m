//
//  ISHyprMXAdapter.m
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HyprMX/HyprMX.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISHyprMXAdapter.h"
#import "ISHyprMXAdapter+Internal.h"
#import "ISHyprMXConstants.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISHyprMXAdapter ()

@end

@implementation ISHyprMXAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return HyprMXAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [HyprMX versionString];
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
    NSString *distributorId = [adData getString:distributorIdKey];
    NSString *propertyId = [adData getString:propertyIdKey];

    if (!distributorId || distributorId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, distributorIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!propertyId || propertyId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, propertyIdKey];
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

            LogAdapterApi_Internal(logDistributorIdAndPropertyId, distributorId, propertyId);

            if ([ISConfigurations getConfigurations].adaptersDebug) {
                [HyprMX setLogLevel:HYPRLogLevelDebug];
            }

            [HyprMX setMediationProvider:mediationName
                      mediatorSDKVersion:[LevelPlay sdkVersion]
                          adapterVersion:HyprMXAdapterVersion];

            [HyprMX initWithDistributorId:distributorId
                               completion:^(BOOL success, NSError *_Nullable error) {
                if (success) {
                    [self initializationSuccess];
                } else {
                    [self initializationFailure];
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

- (void)initializationFailure {
    LogAdapterDelegate_Internal(logInitFailed);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> delegate in initDelegatesList) {
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:logInitFailed];
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

    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];

    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:metaDataAgeRestrictionKey
                                       andValue:formattedValue]) {
        [self setAgeRestrictionValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    [HyprMX setConsentStatus:consent ? CONSENT_GIVEN : CONSENT_DECLINED];
}

- (void)setAgeRestrictionValue:(BOOL)value {
    LogAdapterApi_Internal(logAgeRestriction, value ? @"YES" : @"NO");
    [HyprMX setAgeRestrictedUser:value];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *token = [HyprMX sessionToken];

    if (token.length) {
        LogAdapterApi_Internal(logToken, token);
        NSDictionary *biddingDataDictionary = @{tokenKey: token};
        [delegate successWithBiddingData:biddingDataDictionary];
    } else {
        [delegate failureWithError:logTokenFailed];
    }
}

@end
