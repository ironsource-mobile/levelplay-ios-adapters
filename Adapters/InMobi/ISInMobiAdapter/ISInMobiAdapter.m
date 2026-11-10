//
//  ISInMobiAdapter.m
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISInMobiAdapter.h"
#import "ISInMobiConstants.h"

// Consent and metadata
static NSString *consentCollectingUserData = nil;
static NSNumber *ageRestrictionCollectingUserData = nil;
static NSNumber *doNotSellCollectingUserData = nil;

// Init state
static InitState initState = INIT_STATE_NONE;

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISInMobiAdapter ()

@end

@implementation ISInMobiAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return InMobiAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [IMSdk getVersion];
}

+ (NSString *)networkAdapterVersion {
    return InMobiAdapterVersion;
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
    NSString *accountId = [adData getString:accountIdKey];
    NSString *placementId = [adData getString:placementIdKey];

    // Configuration Validation
    if (!accountId || accountId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, accountIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorMissingParams
                                 errorMessage:errorMessage];
        return;
    }

    if (!placementId || placementId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorMissingParams
                                 errorMessage:errorMessage];
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    if (initState == INIT_STATE_FAILED) {
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorInternal
                                 errorMessage:logInitFailedMessage];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterDelegate_Internal(logAccountIdAndPlacementId, accountId, placementId);

        BOOL isAdapterDebug = [ISConfigurations getConfigurations].adaptersDebug;
        [IMSdk setLogLevel:isAdapterDebug ? IMSDKLogLevelDebug : IMSDKLogLevelNone];
        LogAdapterDelegate_Internal(logSetLogLevel, isAdapterDebug ? @"Debug" : @"None");

        ISInMobiAdapter * __weak weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [IMSdk initWithAccountID:accountId
                   consentDictionary:[weakSelf getConsentDictionary]
                andCompletionHandler:^(NSError *error) {
                __typeof__(self) strongSelf = weakSelf;
                if (error == nil) {
                    [strongSelf initializationSuccess];
                } else {
                    NSString *errorMessage = [NSString stringWithFormat:@"InMobi SDK init failed %@", error ? error.description : @""];
                    [strongSelf initializationFailure:errorMessage];
                }
            }];
        });
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    // Apply collected metadata
    if (ageRestrictionCollectingUserData != nil) {
        BOOL isAgeRestricted = [ageRestrictionCollectingUserData intValue] == 1;
        [self setAgeRestricted:isAgeRestricted];
    }

    // Notify all delegates
    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)initializationFailure:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(logInitFailed, errorMessage);

    initState = INIT_STATE_FAILED;

    // Notify all delegates
    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ISAdapterErrorInternal
                                     errorMessage:errorMessage];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    consentCollectingUserData = consent ? @"true" : @"false";

    if (initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
        [IMSdk updateGDPRConsent:[self getConsentDictionary]];
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
        doNotSellCollectingUserData = [ISMetaDataUtils getMetaDataBooleanValue:value] ? @(1) : @(0);
        return;
    }

    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];

    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:metaDataAgeRestrictedKey
                                       andValue:formattedValue]) {
        [self setAgeRestricted:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setAgeRestricted:(BOOL)isAgeRestricted {
    if (initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logAgeRestricted, isAgeRestricted ? @"YES" : @"NO");
        [IMSdk setIsAgeRestricted:isAgeRestricted];
    } else {
        ageRestrictionCollectingUserData = isAgeRestricted ? @1 : @0;
    }
}

#pragma mark - Helper Methods

- (NSDictionary *)getConsentDictionary {
    if (consentCollectingUserData.length > 0) {
        return @{[IMCommonConstants IM_GDPR_CONSENT_AVAILABLE]: consentCollectingUserData};
    }

    return @{};
}

- (NSDictionary *)extras {
    NSMutableDictionary *extras = [NSMutableDictionary dictionaryWithDictionary:@{
        tpKey: tpValueUnitylevelplay,
        tpVersionKey: InMobiAdapterVersion
    }];

    if (doNotSellCollectingUserData != nil) {
        [extras setObject:doNotSellCollectingUserData
                   forKey:metaDataDoNotSellKey];
    }

    return extras;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenFailed);
        [delegate failureWithError:logTokenFailed];
        return;
    }

    NSString *bidderToken = [IMSdk getTokenWithExtras:[self extras]
                                          andKeywords:@""];
    if (bidderToken.length) {
        LogAdapterApi_Internal(logToken, bidderToken);
        [delegate successWithBiddingData:@{tokenKey: bidderToken}];
    } else {
        LogAdapterApi_Internal(logTokenFailed);
        [delegate failureWithError:logTokenFailed];
    }
}

@end
