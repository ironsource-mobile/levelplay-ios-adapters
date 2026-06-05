//
//  ISBidMachineAdapter.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISBidMachineAdapter.h"
#import "ISBidMachineConstants.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initCallbackDelegates = nil;

@interface ISBidMachineAdapter ()

@end

@implementation ISBidMachineAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return BidMachineAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return BidMachineSdk.sdkVersion;
}

#pragma mark - Initialization Methods And Callbacks

- (instancetype)init {
    self = [super init];
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitializationDelegate> set];
        }
    }
    return self;
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {

    NSString *sourceId = [adData getString:sourceIdKey];

    // Configuration Validation
    if (!sourceId || sourceId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, sourceIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initCallbackDelegates addObject:delegate];
    }

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterDelegate_Internal(logSourceId, sourceId);

        [BidMachineSdk.shared populate:^(id<BidMachineInfoBuilderProtocol> builder) {
            BOOL enableLogs = [ISConfigurations getConfigurations].adaptersDebug;
            [builder withLoggingMode:enableLogs];
            [builder withEventLoggingMode:enableLogs];
            [builder withBidLoggingMode:enableLogs];
        }];

        [BidMachineSdk.shared initializeSdk:sourceId];
        [self initializationSuccess];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initCallbackDelegates removeAllObjects];
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
    [BidMachineSdk.shared.regulationInfo
     populate:^(id<BidMachineRegulationInfoBuilderProtocol> builder) {
        [builder withGDPRZone:YES];
        [builder withGDPRConsent:consent];
    }];
}

- (void)setCCPAValue:(BOOL)ccpa {
    NSString *ccpaConsentString = (ccpa) ? metaDataCCPANoConsentValue : metaDataCCPAConsentValue;
    LogAdapterApi_Internal(logCCPA, ccpaConsentString);
    [BidMachineSdk.shared.regulationInfo
     populate:^(id<BidMachineRegulationInfoBuilderProtocol> builder) {
        [builder withUSPrivacyString:ccpaConsentString];
    }];
}

- (void)setCOPPAValue:(BOOL)coppa {
    LogAdapterApi_Internal(logCOPPA, coppa ? @"YES" : @"NO");
    [BidMachineSdk.shared.regulationInfo
     populate:^(id<BidMachineRegulationInfoBuilderProtocol> builder) {
        [builder withCOPPA:coppa];
    }];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdFormat:(BidMachineAdFormat *)adFormat
                           placementId:(NSString *)placementId
                              delegate:(id<ISBiddingDataDelegate>)delegate {

    // BidMachine token can only be fetched after successful initialization
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSError *placementError = nil;
    BidMachinePlacement *placement = [BidMachineSdk.shared placement:adFormat
                                                               error:&placementError
                                                             builder:^(id<BidMachinePlacementBuilderProtocol> builder) {
        if (placementId.length > 0) {
            [builder withPlacementId:placementId];
        }
    }];

    if (!placement || placementError) {
        LogInternal_Error(logError, placementError.description);
        [delegate failureWithError:placementError.description];
        return;
    }

    [BidMachineSdk.shared tokenWithPlacement:placement completion:^(NSString * _Nullable token) {
        if (!token) {
            LogAdapterApi_Internal(logTokenFailed);
            [delegate failureWithError:logTokenFailed];
            return;
        }

        LogAdapterApi_Internal(logToken, token);
        NSDictionary *biddingDataDictionary = @{tokenKey: token};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
