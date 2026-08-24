//
//  ISSmaatoAdapter.m
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISSmaatoAdapter+Internal.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISSmaatoAdapter () <SmaatoSdkInitialisationDelegate>

@end

@implementation ISSmaatoAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return SmaatoAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [SmaatoSDK sdkVersion];
}

+ (NSString *)networkAdapterVersion {
    return SmaatoAdapterVersion;
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
    NSString *adSpaceId = [adData getString:adSpaceIdKey];

    // Configuration Validation
    if (!publisherId || publisherId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, publisherIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!adSpaceId || adSpaceId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adSpaceIdKey];
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
        LogAdapterApi_Internal(logPublisherId, publisherId);

        initState = INIT_STATE_IN_PROGRESS;

        SMAConfiguration *config = [[SMAConfiguration alloc] initWithPublisherId:publisherId];

        if ([ISConfigurations getConfigurations].adaptersDebug) {
            config.logLevel = kSMALogLevelDebug;
        }

        [SmaatoSDK initSDKWithConfig:config
                         andDelegate:self];
    });
}

#pragma mark - SmaatoSdkInitialisationDelegate

- (void)onInitialisationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

- (void)onInitialisationFailure:(NSString *_Nullable)errorMessage {
    LogAdapterDelegate_Internal(logError, errorMessage);

    initState = INIT_STATE_FAILED;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED
                                    errorMessage:errorMessage];
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
    }
}

- (void)setCCPAValue:(BOOL)doNotSell {
    NSString *ccpaValue = doNotSell ? metaDataCCPANoConsentValue : metaDataCCPAConsentValue;
    LogAdapterApi_Internal(logMetaDataSet, metaDataCCPAKey, ccpaValue);
    [NSUserDefaults.standardUserDefaults setObject:ccpaValue
                                            forKey:metaDataCCPAKey];
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");

    SmaatoSDK.isLGPDConsentEnabled = @(consent);
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logError, logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSString *bidderToken = [SmaatoSDK collectSignals];
    NSString *returnedToken = bidderToken ? bidderToken : @"";

    LogAdapterApi_Internal(logToken, returnedToken);
    [delegate successWithBiddingData:@{tokenKey: returnedToken}];
}

- (SMAAdRequestParams *)getAdRequestWithServerData:(NSString *)serverData {
    SMAAdRequestParams *adRequestParams;
    NSError *error;
    NSData *data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
    SMAInAppBid *inAppBid = [SMAInAppBid bidWithResponseData:data];
    NSString *uniqueId = [SMAInAppBidding saveBid:inAppBid error:&error];

    if (error == nil) {
        adRequestParams = [SMAAdRequestParams new];
        adRequestParams.ubUniqueId = uniqueId;
    }

    return adRequestParams;
}

@end
