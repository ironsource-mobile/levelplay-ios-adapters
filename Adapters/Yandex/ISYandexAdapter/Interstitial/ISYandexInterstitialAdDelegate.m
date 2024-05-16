//
//  ISYandexInterstitialAdDelegate.m
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexInterstitialAdapter.h"
#import "ISYandexInterstitialAdDelegate.h"

@implementation ISYandexInterstitialAdDelegate

- (instancetype)initWithAdapter:(ISYandexInterstitialAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Notifies that the ad loaded successfully.
/// @param adLoader A reference to an object of the InterstitialAdLoader class that invoked the method.
/// @param interstitialAd Interstitial ad that is loaded and ready to be displayed.
- (void)interstitialAdLoader:(YMAInterstitialAdLoader * _Nonnull)adLoader 
                     didLoad:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);

    [self.adapter onAdUnitAvailabilityChangeWithAdUnitId:self.adUnitId
                                            availability:YES
                                          interstitialAd:interstitialAd];
    
    [self.delegate adapterInterstitialDidLoad];
}
/// Notifies that the ad failed to load.
/// @param adLoader A reference to an object of the InterstitialAdLoader class that invoked the method.
/// @param error Information about the error (for details, see AdErrorCode).
- (void)interstitialAdLoader:(YMAInterstitialAdLoader * _Nonnull)adLoader
      didFailToLoadWithError:(YMAAdRequestError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error.error);
    NSError *smashError = error.error.code == YMAAdErrorCodeNoFill ? [ISError createError:ERROR_IS_LOAD_NO_FILL
                                                                              withMessage:@"Yandex no fill"] : error.error;
    
    [self.adapter onAdUnitAvailabilityChangeWithAdUnitId:self.adUnitId
                                            availability:NO
                                          interstitialAd:nil];
    
    [self.delegate adapterInterstitialDidFailToLoadWithError:smashError];
}

/// Called after the interstitial ad shows.
/// @param interstitialAd A reference to an object of the InterstitialAd class that invoked the method.
- (void)interstitialAdDidShow:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidOpen];
}

/// Notifies that the ad can’t be displayed.
/// @param interstitialAd A reference to an object of the InterstitialAd class that invoked the method.
/// @param error Information about the error (for details, see AdErrorCode).
- (void)interstitialAd:(YMAInterstitialAd * _Nonnull)interstitialAd
didFailToShowWithError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

/// Notifies delegate when an impression was tracked.
/// @param interstitialAd A reference to an object of the InterstitialAd class that invoked the method.
/// @param impressionData Ad impression-level revenue data.
- (void)interstitialAd:(YMAInterstitialAd * _Nonnull)interstitialAd
didTrackImpressionWithData:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidShow];
}

/// Notifies that the user has clicked on the ad.
/// @param interstitialAd A reference to an object of the InterstitialAd class that invoked the method.
- (void)interstitialAdDidClick:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClick];
}
/// Called after dismissing the interstitial ad.
/// @param interstitialAd A reference to an object of the InterstitialAd class that invoked the method.
- (void)interstitialAdDidDismiss:(YMAInterstitialAd * _Nonnull)interstitialAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClose];
}

@end
