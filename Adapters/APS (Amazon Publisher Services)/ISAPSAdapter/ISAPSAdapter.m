//
//  ISAPSAdapter.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import "ISAPSAdapter+Internal.h"
#import "ISAPSLoadDelegate.h"

static NSString *usPrivacyValue = usPrivacyNotApplicable;

@interface ISAPSAdapter () <ISSetAPSDataProtocol>

@end

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

- (void)setAPSDataWithAdUnit:(NSString *)adUnit apsData:(NSDictionary *)apsData {
    LogAdapterApi_Error(logAPSHandledByMediation);
}

#pragma mark - Initialization Methods And Callbacks

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

    [delegate onInitDidSucceed];
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
