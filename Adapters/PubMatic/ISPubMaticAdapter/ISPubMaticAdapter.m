//
//  ISPubMaticAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISPubMaticAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@implementation ISPubMaticAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return PubMaticAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [OpenWrapSDK version];
}

+ (NSString *)networkAdapterVersion {
    return PubMaticAdapterVersion;
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
    NSString *publisherId = [adData getString:publisherIdKey];
    NSNumber *profileId = [adData getNumber:profileIdKey];

    // Configuration Validation
    if (!publisherId || publisherId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, publisherIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!profileId) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, profileIdKey];
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
        LogAdapterApi_Internal(logPublisherIdAndProfileId, publisherId, profileId);

        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [OpenWrapSDK setLogLevel:POBSDKLogLevelDebug];
        }

        initState = INIT_STATE_IN_PROGRESS;

        ISPubMaticAdapter * __weak weakSelf = self;
        OpenWrapSDKConfig *config = [[OpenWrapSDKConfig alloc] initWithPublisherId:publisherId
                                                                    andProfileIds:@[profileId]];
        [OpenWrapSDK initializeWithConfig:config
                     andCompletionHandler:^(BOOL success, NSError *error) {
            __typeof__(self) strongSelf = weakSelf;
            if (success) {
                [strongSelf initializationSuccess];
            } else {
                [strongSelf initializationFailure:error];
            }
        }];
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

- (void)initializationFailure:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED
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

    // This is an array of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(logMetaDataSet, key, value);

    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];

    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:metaDataCOPPAKey
                                       andValue:formattedValue]) {
        [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setCOPPAValue:(BOOL)coppa {
    LogAdapterApi_Internal(logCOPPA, coppa ? @"YES" : @"NO");
    [OpenWrapSDK setCoppaEnabled:coppa];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                              adFormat:(POBAdFormat)adFormat {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logError, logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    POBSignalConfig *signalConfig = [[POBSignalConfig alloc] initWithAdFormat:adFormat];
    NSString *signal = [POBSignalGenerator generateSignalForBiddingHost:POBSDKBiddingHostUnityLevelPlay
                                                              andConfig:signalConfig];
    NSString *returnedToken = signal ?: @"";

    LogAdapterApi_Internal(logToken, returnedToken);
    [delegate successWithBiddingData:@{tokenKey: returnedToken}];
}

@end
