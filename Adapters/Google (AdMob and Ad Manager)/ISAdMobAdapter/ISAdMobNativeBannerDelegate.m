//
//  ISAdMobNativeBannerDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#include <ISAdMobNativeBannerDelegate.h>

@implementation ISAdMobNativeBannerDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                  nativeTemplate:(ISAdMobNativeBannerTemplate*)nativeTemplate
                        delegate:(id<ISAdMobNativeBannerDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _nativeTemplate = nativeTemplate;
        _delegate = delegate;
    }
    return self;
}

/// Called when a native ad is received.
- (void)adLoader:(nonnull GADAdLoader *)adLoader didReceiveNativeAd:(nonnull GADNativeAd *)nativeAd {
    [_delegate onNativeBannerDidLoadWithAdUnitId:adLoader.adUnitID
                                        nativeAd:nativeAd
                                  nativeTemplate:self.nativeTemplate];
}

/// Called when adLoader fails to load an ad.
- (void)adLoader:(nonnull GADAdLoader *)adLoader
    didFailToReceiveAdWithError:(nonnull NSError *)error {
    [_delegate onNativeBannerDidFailToLoadWithAdUnitId:adLoader.adUnitID
                                                 error:error];
}

/// Called when an impression is recorded for an ad.
- (void)nativeAdDidRecordImpression:(GADNativeAd *)nativeAd {
    [_delegate onNativeBannerDidShow:_adUnitId];
}

/// Called when a click is recorded for an ad.
- (void)nativeAdDidRecordClick:(GADNativeAd *)nativeAd {
    [_delegate onNativeBannerDidClick:_adUnitId];
}

#pragma mark  Click-Time Lifecycle Notifications
/// Called before presenting the user a full screen view in response to an ad action. Use this
/// opportunity to stop animations, time sensitive interactions, etc.
///
/// Normally the user looks at the ad, dismisses it, and control returns to your application with
/// the nativeAdDidDismissScreen: message. However, if the user hits the Home button or clicks on an
/// App Store link, your application will be backgrounded. The next method called will be the
/// applicationWillResignActive: of your UIApplicationDelegate object.
- (void)nativeAdWillPresentScreen:(GADNativeAd *)nativeAd {
    [_delegate onNativeBannerWillPresentScreen:_adUnitId];
}

/// Called after dismissing a full screen view. Use this opportunity to restart anything you may
/// have stopped as part of nativeAdWillPresentScreen:.
- (void)nativeAdDidDismissScreen:(GADNativeAd *)nativeAd {
    [_delegate onNativeBannerDidDismissScreen:_adUnitId];
}

@end
