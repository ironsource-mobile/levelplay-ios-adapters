//
//  ISYandexInterstitialAdapter.m
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

@import YandexMobileAds;
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISYandexInterstitialAdapter.h"
#import "ISYandexInterstitialDelegate.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"

@interface ISYandexInterstitialAdapter ()

@property (nonatomic, strong) YMAInterstitialAd *interstitialAd;
@property (nonatomic, strong) YMAInterstitialAdLoader *interstitialAdLoader;
@property (nonatomic, strong) ISYandexInterstitialDelegate *interstitialAdDelegate;
@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISYandexInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    // validate adUnitId
    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.adAvailability = NO;

    // create delegate for showing ads
    self.interstitialAdDelegate = [[ISYandexInterstitialDelegate alloc] initWithDelegate:delegate];

    // create adLoader
    self.interstitialAdLoader = [[YMAInterstitialAdLoader alloc] init];

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
    YMAAdRequest *adRequest = [adapter createAdRequestWithBidResponse:adData.serverData
                                                              adUnitId:adUnitId];

    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self) weakSelf = self;
        [self.interstitialAdLoader loadAdWith:adRequest completionHandler:^(YMAInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }

            if (error) {
                LogAdapterDelegate_Internal(logCallbackFailed, adUnitId, error.localizedDescription);
                ISAdapterErrorType errorType = (error.code == yandexNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
                strongSelf.interstitialAd = nil;
                strongSelf.adAvailability = NO;
                [delegate adDidFailToLoadWithErrorType:errorType
                                             errorCode:error.code
                                          errorMessage:error.localizedDescription];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Store ad object first to retain it
                    strongSelf.interstitialAd = interstitialAd;
                    strongSelf.interstitialAd.delegate = strongSelf.interstitialAdDelegate;
                    strongSelf.adAvailability = YES;

                    // Extract creative IDs and pass as extra data if available
                    NSString *creativeId = [ISYandexAdapter buildCreativeIdStringFromCreatives:strongSelf.interstitialAd.adInfo.creatives];
                    LogAdapterDelegate_Internal(logCreativeId, creativeId);

                    if (creativeId.length) {
                        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
                        [delegate adDidLoadWithExtraData:extraData];
                    } else {
                        [delegate adDidLoad];
                    }
                });
            }
        }];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showFromViewController:viewController];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd.delegate = nil;
        self.interstitialAd = nil;
        self.interstitialAdLoader = nil;
        self.interstitialAdDelegate = nil;
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.adAvailability;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    YMABidderTokenRequest *requestConfiguration = [YMABidderTokenRequest interstitialWithTargeting:nil
                                                                                        parameters:[adapter getConfigParams]];

    [adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                delegate:delegate];
}

@end
