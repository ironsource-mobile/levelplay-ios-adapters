//
//  ISUnityAdsRewardedAdapter.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISUnityAdsRewardedAdapter.h"
#import "ISUnityAdsRewardedDelegate.h"
#import "ISUnityAdsAdapter+Internal.h"

@interface ISUnityAdsRewardedAdapter ()

@property (nonatomic, strong) UADSRewardedAd *rewardedAd;
@property (nonatomic, strong) ISUnityAdsRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISUnityAdsRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    ISUnityAdsAdapter *adapter = (ISUnityAdsAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    UADSLoadConfigurationBuilder *builder = [[UADSLoadConfigurationBuilder alloc] initWithPlacementId:placementId];

    if (adData.serverData != nil) {
        builder = [builder withAdMarkup:adData.serverData];
    }

    builder = [builder withMediationInfo:[adapter adapterMediationInfo]];
    builder = [builder withMediationAdUnitId:placementId];

    [UADSRewardedAd load:[builder build]
        completion:^(UADSRewardedAd * _Nullable ad, id<UnityAdsError> _Nullable error) {

        if (ad == nil) {
            LogAdapterDelegate_Internal(logError, error.message);
            BOOL isNoFill = error.code == unityAdsNoFillErrorCode;
            [delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                         errorCode:(isNoFill ? ERROR_RV_LOAD_NO_FILL : error.code)
                                      errorMessage:error.message];
            return;
        }

        LogAdapterDelegate_Internal(logPlacementId, placementId);
        self.rewardedAd = ad;
        [delegate adDidLoad];
    }];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    UADSShowConfigurationBuilder *builder = [[UADSShowConfigurationBuilder alloc] init];

    if ([self dynamicUserId]) {
        builder = [builder withCustomRewardString:[self dynamicUserId]];
    }

    builder = [builder withViewController:viewController];

    self.rewardedAdDelegate = [[ISUnityAdsRewardedDelegate alloc] initWithDelegate:delegate];
    [self.rewardedAd show:[builder build] delegate:self.rewardedAdDelegate];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd = nil;
        self.rewardedAdDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISUnityAdsAdapter *adapter = (ISUnityAdsAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithAdData:adData
                                 adFormat:UADSAdFormatRewarded
                                 delegate:delegate];
}

@end
