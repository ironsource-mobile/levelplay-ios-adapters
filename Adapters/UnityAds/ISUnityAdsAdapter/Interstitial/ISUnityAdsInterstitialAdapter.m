//
//  ISUnityAdsInterstitialAdapter.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISUnityAdsInterstitialAdapter.h"
#import "ISUnityAdsInterstitialDelegate.h"
#import "ISUnityAdsAdapter+Internal.h"

@interface ISUnityAdsInterstitialAdapter ()

@property (nonatomic, strong) UADSInterstitialAd *interstitialAd;
@property (nonatomic, strong) ISUnityAdsInterstitialDelegate *interstitialAdDelegate;

@end

@implementation ISUnityAdsInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
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

    [UADSInterstitialAd load:[builder build]
        completion:^(UADSInterstitialAd * _Nullable ad, id<UnityAdsError> _Nullable error) {

        if (ad == nil) {
            LogAdapterDelegate_Internal(logError, error.message);
            BOOL isNoFill = error.code == unityAdsNoFillErrorCode;
            [delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                         errorCode:(isNoFill ? ERROR_IS_LOAD_NO_FILL : error.code)
                                      errorMessage:error.message];
            return;
        }

        LogAdapterDelegate_Internal(logPlacementId, placementId);
        self.interstitialAd = ad;
        [delegate adDidLoad];
    }];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
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

    builder = [builder withViewController:viewController];

    self.interstitialAdDelegate = [[ISUnityAdsInterstitialDelegate alloc] initWithDelegate:delegate];
    [self.interstitialAd show:[builder build] delegate:self.interstitialAdDelegate];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = nil;
        self.interstitialAdDelegate = nil;
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
                                 adFormat:UADSAdFormatInterstitial
                                 delegate:delegate];
}

@end
