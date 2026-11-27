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

@interface ISBidMachineConsentProvider : NSObject <BidMachineConsentProvider>

@property (nonatomic, strong, nullable) NSNumber *coppa;
@property (nonatomic, strong, nullable) NSNumber *gdprApplies;
@property (nonatomic, strong, nullable) NSNumber *gdprConsent;
@property (nonatomic, strong, nullable) NSNumber *nonPersonalized;
@property (nonatomic, copy, nullable) NSString *gppString;
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *gppSids;

@end

@implementation ISBidMachineConsentProvider

@end

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initCallbackDelegates = nil;
static BidMachineInstance *bidMachineInstance = nil;
static ISBidMachineConsentProvider *consentProvider = nil;

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

+ (NSString *)networkAdapterVersion {
    return BidMachineAdapterVersion;
}

#pragma mark - Initialization Methods And Callbacks

- (instancetype)init {
    self = [super init];
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitializationDelegate> set];
        }
        if (consentProvider == nil) {
            consentProvider = [[ISBidMachineConsentProvider alloc] init];
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

        BidMachineSdk.isLoggingEnabled = [ISConfigurations getConfigurations].adaptersDebug;

        BidMachineConfiguration *configuration = [[BidMachineConfiguration alloc] init];
        configuration.mediationInfo = [[BidMachineMediationInfo alloc] initWithName:mediationName
                                                                            version:[LevelPlay sdkVersion]
                                                                     adapterVersion:BidMachineAdapterVersion];

        bidMachineInstance = [BidMachineSdk initializeWithSourceId:sourceId
                                                     configuration:configuration];
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

    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];
    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:metaDataCOPPAKey
                                       andValue:formattedValue]) {
        [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    consentProvider.gdprApplies = @YES;
    consentProvider.gdprConsent = @(consent);
    BidMachineSdk.consentProvider = consentProvider;
}

- (void)setCOPPAValue:(BOOL)coppa {
    LogAdapterApi_Internal(logCOPPA, coppa ? @"YES" : @"NO");
    consentProvider.coppa = @(coppa);
    BidMachineSdk.consentProvider = consentProvider;
}

#pragma mark - Helper Methods

+ (BidMachineInstance *)bidMachineInstance {
    return bidMachineInstance;
}

- (void)collectBiddingDataWithPlacementId:(NSString *)placementId
                                 delegate:(id<ISBiddingDataDelegate>)delegate {

    // BidMachine token can only be fetched after successful initialization
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    NSMutableArray<BidMachinePlacement *> *placements = [NSMutableArray array];
    if (placementId.length > 0) {
        [placements addObject:[[BidMachinePlacement alloc] initWithId:placementId extras:@{}]];
    }

    [bidMachineInstance collectTokenWithPlacements:placements
                                        completion:^(NSString * _Nullable token, BidMachineError * _Nullable error) {
        if (error) {
            LogInternal_Error(logError, error.description);
            [delegate failureWithError:error.description];
            return;
        }

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
