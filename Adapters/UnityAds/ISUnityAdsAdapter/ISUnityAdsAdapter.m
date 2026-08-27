//
//  ISUnityAdsAdapter.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISUnityAdsAdapter+Internal.h"

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@interface ISUnityAdsAdapter ()

@property (nonatomic, strong) NSObject *unityAdsStorageLock;

@end

@implementation ISUnityAdsAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return UnityAdsAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [UnityAds getVersion];
}

+ (NSString *)networkAdapterVersion {
    return UnityAdsAdapterVersion;
}

#pragma mark - Initialization Methods And Callbacks

- (instancetype)init {
    self = [super init];
    if (self) {
        if (initializationDelegates == nil) {
            initializationDelegates = [ISConcurrentMutableSet<ISNetworkInitializationDelegate> set];
        }
        _unityAdsStorageLock = [NSObject new];
    }
    return self;
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    NSString *gameId = [adData getString:gameIdKey];
    NSString *placementId = [adData getString:placementIdKey];

    // Configuration Validation
    if (!gameId || gameId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, gameIdKey];
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

    LogAdapterApi_Internal(logGameIdAndPlacementId, gameId, placementId);

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    if (initState == INIT_STATE_FAILED) {
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:logInitFailedMessage];
        return;
    }

    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        UADSInitializationConfigurationBuilder *builder = [[UADSInitializationConfigurationBuilder alloc] initWithGameId:gameId];
        builder = [builder withTestMode:NO];
        builder = [builder withLogLevel:[ISConfigurations getConfigurations].adaptersDebug ? UADSLogLevelDebug : UADSLogLevelInfo];
        builder = [builder withMediationInfo:[self adapterMediationInfo]];
        builder = [builder withExtras:[self initializationExtrasFrom:adData]];

        [UnityAds initialize:[builder build]
                  completion:^(id<UnityAdsError> _Nullable error) {
            if (error == nil) {
                [self initializationSuccess];
            } else {
                [self initializationFailureWithMessage:[NSString stringWithFormat:logInitFailedWithError,
                                                        @(error.code), error.message]];
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

- (void)initializationFailureWithMessage:(NSString *)errorMessage {
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

- (void)setCCPAValue:(BOOL)value {
    // The UnityAds CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the ironSource Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    [self setUnityAdsMetaDataWithKey:ccpaUnityAdsFlag
                               value:optIn];
    [UnityAds setUserOptOut:value];
}

- (void)setConsent:(BOOL)consent {
    [self setUnityAdsMetaDataWithKey:gdprUnityAdsFlag
                               value:consent];
    [UnityAds setUserConsent:consent];
}

- (void)setCOPPAValue:(BOOL)value {
    [self setUnityAdsMetaDataWithKey:coppaUnityAdsFlag
                               value:value];
    [UnityAds setNonBehavioral:value];
}

#pragma mark - Helper Methods

- (void)setUnityAdsMetaDataWithKey:(NSString *)key
                             value:(BOOL)value {
    LogAdapterApi_Internal(logMetaDataSet, key, value ? @"YES" : @"NO");

    @synchronized (self.unityAdsStorageLock) {
        UADSMetaData *unityAdsMetaData = [[UADSMetaData alloc] init];
        [unityAdsMetaData set:key value:value ? @YES : @NO];
        [unityAdsMetaData commit];
    }
}

- (UADSMediationInfo *)adapterMediationInfo {
    return [[UADSMediationInfo alloc] initWithName:mediationName
                                           version:[LevelPlay sdkVersion]
                                    adapterVersion:UnityAdsAdapterVersion];
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            adFormat:(UADSAdFormat)format
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    UADSTokenConfigurationBuilder *builder = [[UADSTokenConfigurationBuilder alloc] initWithAdFormat:format];
    builder = [builder withMediationInfo:[self adapterMediationInfo]];

    id bannerSizeValue = [adData getAdUnitData][bannerSizeKey];
    if ([bannerSizeValue isKindOfClass:[ISBannerSize class]]) {
        ISBannerSize *bannerSize = (ISBannerSize *)bannerSizeValue;
        builder = [builder withBannerSize:CGSizeMake(bannerSize.width, bannerSize.height)];
    }

    NSString *placementId = [adData getString:placementIdKey];
    if (placementId != nil) {
        builder = [builder withPlacementId:placementId];
        builder = [builder withMediationAdUnitId:placementId];
    }

    [UnityAds getToken:[builder build] completion:^(NSString * _Nullable token) {
        if (token != nil && ![token isEqualToString:@""]) {
            LogAdapterApi_Internal(logToken, token);
            [delegate successWithBiddingData:@{tokenKey: token}];
        } else {
            LogAdapterApi_Internal(logError, logEmptyToken);
            [delegate failureWithError:logEmptyToken];
        }
    }];
}

- (NSDictionary *)initializationExtrasFrom:(ISAdData *)adData {
    NSMutableDictionary<NSString *, NSString *> *extras = [NSMutableDictionary dictionary];

    NSString *blob = [adData getString:unityAdsInitBlobKey];
    if ([blob isKindOfClass:NSString.class]) {
        extras[unityAdsInitBlobKey] = blob;
    }

    id traitsObject = adData.configuration[unityAdsEpTraitsKey];
    if ([traitsObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *traits = (NSDictionary *)traitsObject;

        for (id key in traits) {
            if (![key isKindOfClass:NSString.class]) {
                continue;
            }

            id value = traits[key];
            if ([value isKindOfClass:NSString.class]) {
                extras[key] = value;
            } else if ([value isKindOfClass:NSNumber.class]) {
                extras[key] = [((NSNumber *)value) stringValue];
            }
        }
    }

    return extras;
}

@end
