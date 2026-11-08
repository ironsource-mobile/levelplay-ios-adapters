//
//  ISAPSAdapter.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISAPSAdapter+Internal.h"
#import "ISAPSLoadDelegate.h"

static NSString *usPrivacyValue = usPrivacyNotApplicable;

static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;
static BOOL isTestMode = NO;

@implementation ISAPSAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return APSAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [DTBAds version];
}

+ (NSString *)networkAdapterVersion {
    return APSAdapterVersion;
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
    NSString *uuid = [adData getString:uuidKey];

    // Configuration Validation
    if (!uuid || uuid.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingConfigurationParam, uuidKey];
        LogAdapterApi_Error(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    LogAdapterApi_Internal(logUuid, uuid);

    NSString *appId = [adData getString:appIdKey];

    if (!appId || appId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingConfigurationParam, appIdKey];
        LogAdapterApi_Error(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    if (initState == INIT_STATE_FAILED) {
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorInternal errorMessage:logInitFailed];
        return;
    }

    if (delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterApi_Internal(logAppId, appId);

        initState = INIT_STATE_IN_PROGRESS;

        __weak typeof(self) weakSelf = self;
        [APS initializeWithAppKey:appId
                       completion:^(NSError * _Nullable error) {
            __typeof__(self) strongSelf = weakSelf;
            if (error) {
                LogAdapterDelegate_Internal(logError, error.localizedDescription);
                [strongSelf initializationFailure];
            } else {
                [strongSelf initializationSuccess];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    if (isTestMode) {
        [self applyTestMode:YES];
    }

    initState = INIT_STATE_SUCCESS;

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
                                     errorMessage:logInitFailed];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Test Mode

- (void)setTestMode:(BOOL)enabled {
    LogAdapterApi_Internal(logTestMode, enabled ? @"YES" : @"NO");
    isTestMode = enabled;

    if (initState == INIT_STATE_SUCCESS) {
        [self applyTestMode:enabled];
    }
}

- (void)applyTestMode:(BOOL)enabled {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [DTBAds sharedInstance].testMode = enabled;
#pragma clang diagnostic pop
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray<NSString *> *)values {
    if (values.count == 0) {
        return;
    }

    NSString *value = values[0];
    LogAdapterApi_Internal(logMetaDataSet, key, value);

    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
    }
}

- (void)setCCPAValue:(BOOL)doNotSell {
    LogAdapterApi_Internal(logCCPA, doNotSell ? @"YES" : @"NO");
    usPrivacyValue = doNotSell ? usPrivacyOptOut : usPrivacyOptIn;
}

#pragma mark - Helper Methods

+ (NSString *)errorFromCode:(DTBAdErrorCode)errorCode {
    switch (errorCode) {
        case SampleErrorCodeBadRequest:
            return errorBadRequest;
        case SampleErrorCodeUnknown:
            return errorUnknown;
        case SampleErrorCodeNetworkError:
            return errorNetwork;
        case SampleErrorCodeNoInventory:
            return errorNoInventory;
        default:
            return [NSString stringWithFormat:errorUnknownCode, (int)errorCode];
    }
}

- (void)collectBiddingInfoWithSize:(DTBAdSize *)size
                          delegate:(id<ISBiddingDataDelegate>)delegate
                        completion:(void (^)(DTBAdResponse *))completion {
    ISAPSLoadDelegate *loadDelegate = [[ISAPSLoadDelegate alloc] initWithDelegate:delegate
                                                                       completion:completion];

    if (!size.slotUUID.length) {
        [loadDelegate onFailure:REQUEST_ERROR];
        return;
    }

    DTBAdNetworkInfo *info = [[DTBAdNetworkInfo alloc] initWithNetworkName:DTBADNETWORK_UNITY_LEVELPLAY];
    DTBAdLoader *adLoader = [[DTBAdLoader alloc] initWithAdNetworkInfo:info];

    // Add U.S. Privacy String as a custom target on the bid request
    NSDictionary *privacyStrings = [self getUSPrivacyStrings];
    for (NSString *key in privacyStrings) {
        [adLoader putCustomTarget:privacyStrings[key] withKey:key];
    }

    [adLoader setAdSizes:@[ size ]];
    [adLoader loadAd:loadDelegate];
}

- (DTBAdSize *)createVideoAdSizeWithSlotUUID:(NSString *)slotUUID {
    BOOL isLandscape = UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
    NSInteger width = isLandscape ? videoLandscapeWidth : videoPortraitWidth;
    NSInteger height = isLandscape ? videoLandscapeHeight : videoPortraitHeight;
    return [[DTBAdSize alloc] initVideoAdSizeWithPlayerWidth:width
                                                      height:height
                                                 andSlotUUID:slotUUID];
}

- (NSDictionary<NSString *, NSString *> *)getUSPrivacyStrings {
    LogAdapterApi_Internal(logUSPrivacy, usPrivacyKey, usPrivacyValue);
    return @{usPrivacyKey : usPrivacyValue};
}

@end
