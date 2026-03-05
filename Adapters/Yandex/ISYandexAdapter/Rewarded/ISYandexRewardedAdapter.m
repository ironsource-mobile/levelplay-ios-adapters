//
//  ISYandexRewardedAdapter.m
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISYandexRewardedAdapter.h"
#import "ISYandexRewardedDelegate.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"

@interface ISYandexRewardedAdapter ()

@property (nonatomic, strong) YMARewardedAd *ad;
@property (nonatomic, strong) YMARewardedAdLoader *adLoader;
@property (nonatomic, strong) ISYandexRewardedDelegate *yandexAdDelegate;
@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISYandexRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    // validate adUnitId
    if (!adUnitId || adUnitId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingAdUnitId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.adAvailability = NO;

    // create delegate
    ISYandexRewardedDelegate *adDelegate = [[ISYandexRewardedDelegate alloc] initWithAdapter:self
                                                                                     adUnitId:adUnitId
                                                                                  andDelegate:delegate];
    self.yandexAdDelegate = adDelegate;

    // create adLoader
    YMARewardedAdLoader *adLoader = [[YMARewardedAdLoader alloc] init];
    adLoader.delegate = adDelegate;
    self.adLoader = adLoader;

    // get ad request parameters from adapter
    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }
    YMAAdRequestConfiguration *adRequest = [adapter createAdRequestWithBidResponse:adData.serverData
                                                                           adUnitId:adUnitId];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.adLoader loadAdWithRequestConfiguration:adRequest];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        self.adAvailability = NO;
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad showFromViewController:viewController];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    self.ad.delegate = nil;
    self.ad = nil;
    self.adLoader.delegate = nil;
    self.adLoader = nil;
    self.yandexAdDelegate = nil;
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.ad != nil && self.adAvailability;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    YMABidderTokenRequestConfiguration *requestConfiguration = [[YMABidderTokenRequestConfiguration alloc] initWithAdType:YMAAdTypeRewarded];

    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    requestConfiguration.parameters = [adapter getConfigParams];

    [adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                delegate:delegate];
}

- (void)setAdAvailability:(BOOL)availability
           withRewardedAd:(YMARewardedAd *)rewardedAd {
    self.ad = rewardedAd;
    self.ad.delegate = self.yandexAdDelegate;
    self.adAvailability = availability;
}

@end
