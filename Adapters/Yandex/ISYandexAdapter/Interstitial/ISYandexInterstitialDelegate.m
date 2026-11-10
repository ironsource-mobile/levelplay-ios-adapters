//
//  ISYandexInterstitialDelegate.m
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YandexMobileAds;
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISYandexInterstitialDelegate.h"
#import "ISYandexInterstitialAdapter.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexConstants.h"

@implementation ISYandexInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// Called after the interstitial ad shows.
- (void)interstitialAdDidShow:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

/// Notifies that the ad can't be displayed.
- (void)interstitialAd:(YMAInterstitialAd * _Nonnull)interstitialAd
didFailToShowWithError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error);
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
