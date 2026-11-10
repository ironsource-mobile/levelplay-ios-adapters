//
//  ISFacebookAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <FBAudienceNetwork/FBAdSettings.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISFacebookAdapter.h"
#import "ISFacebookConstants.h"

// Init state
static InitState initState = INIT_STATE_NONE;

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

static NSString *mediationService = nil;

@implementation ISFacebookAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return FacebookAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return FB_AD_SDK_VERSION;
}

+ (NSString *)networkAdapterVersion {
    return FacebookAdapterVersion;
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
    NSString *placementIds = [adData getString:placementIdsKey];

    // Configuration Validation
    if (!placementIds || placementIds.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdsKey];
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

        NSArray *placementIdsArray = [placementIds componentsSeparatedByString:@","];

        FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:placementIdsArray
                                                                       mediationService:[self getMediationService]];

        FBAdLogLevel logLevel = [ISConfigurations getConfigurations].adaptersDebug ? FBAdLogLevelVerbose : FBAdLogLevelNone;
        [FBAdSettings setLogLevel:logLevel];

        LogAdapterApi_Internal(logPlacementIds, placementIdsArray);

        ISFacebookAdapter * __weak weakSelf = self;
        [FBAudienceNetworkAds initializeWithSettings:initSettings
                                   completionHandler:^(FBAdInitResults *results) {
            __typeof__(self) strongSelf = weakSelf;
            if (results.success) {
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

    // set mediation service
    [FBAdSettings setMediationService:[self getMediationService]];

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
        [initDelegate onInitDidFailWithErrorCode:ISAdapterErrorInternal
                                    errorMessage:logInitFailedMessage];
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
                                           flag:metaDataMixedAudienceKey
                                       andValue:formattedValue]) {
        [self setMixedAudience:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setMixedAudience:(BOOL)isMixedAudience {
    LogAdapterApi_Internal(logMixedAudience, isMixedAudience ? @"YES" : @"NO");
    [FBAdSettings setMixedAudience:isMixedAudience];
}

#pragma mark - Test Mode

- (void)setTestMode:(BOOL)enabled {
    LogAdapterApi_Internal(logTestMode, enabled ? @"YES" : @"NO");
    if (enabled) {
        [FBAdSettings addTestDevice:[FBAdSettings testDeviceHash]];
    } else {
        [FBAdSettings clearTestDevice:[FBAdSettings testDeviceHash]];
    }
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState == INIT_STATE_FAILED) {
        LogAdapterApi_Internal(logTokenFailed);
        [delegate failureWithError:logTokenFailed];
        return;
    }

    NSString *bidderToken = [FBAdSettings bidderToken];
    NSString *returnedToken = bidderToken ? bidderToken : @"";
    LogAdapterApi_Internal(logToken, returnedToken);
    [delegate successWithBiddingData:@{tokenKey: returnedToken}];
}

- (NSString *)getMediationService {
    if (!mediationService) {
        mediationService = [NSString stringWithFormat:mediationServiceFormat, mediationName, [LevelPlay sdkVersion], FacebookAdapterVersion];
        LogAdapterApi_Internal(logMediationService, mediationService);
    }

    return mediationService;
}

@end
