//
//  ISYandexInterstitialDelegate.m
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISYandexInterstitialDelegate.h"
#import "ISYandexInterstitialAdapter.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexConstants.h"

@implementation ISYandexInterstitialDelegate

- (instancetype)initWithAdapter:(ISYandexInterstitialAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Notifies that the ad loaded successfully.
- (void)interstitialAdLoader:(YMAInterstitialAdLoader * _Nonnull)adLoader
                     didLoad:(YMAInterstitialAd * _Nonnull)interstitialAd {
    [self.adapter setAdAvailability:YES
                 withInterstitialAd:interstitialAd];

    // Extract creative IDs and pass as extra data if available
    NSString *creativeId = [ISYandexAdapter buildCreativeIdStringFromCreatives:interstitialAd.adInfo.creatives];
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithExtraData:extraData];
    } else {
        [self.delegate adDidLoad];
    }
}

/// Notifies that the ad failed to load.
- (void)interstitialAdLoader:(YMAInterstitialAdLoader * _Nonnull)adLoader
      didFailToLoadWithError:(YMAAdRequestError * _Nonnull)error {
    LogAdapterDelegate_Internal(logCallbackFailed, self.adUnitId, error.error.localizedDescription);

    ISAdapterErrorType errorType = (error.error.code == yandexNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.adapter setAdAvailability:NO
                 withInterstitialAd:nil];

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.error.code
                                   errorMessage:error.error.localizedDescription];
}

/// Called after the interstitial ad shows.
- (void)interstitialAdDidShow:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

/// Notifies that the ad can't be displayed.
- (void)interstitialAd:(YMAInterstitialAd * _Nonnull)interstitialAd
didFailToShowWithError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logCallbackFailed, self.adUnitId, error.localizedDescription);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// Notifies delegate when an impression was tracked.
- (void)interstitialAd:(YMAInterstitialAd * _Nonnull)interstitialAd
didTrackImpressionWithData:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Notifies that the user has clicked on the ad.
- (void)interstitialAdDidClick:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Called after dismissing the interstitial ad.
- (void)interstitialAdDidDismiss:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
