//
//  ISAdMobNativeBannerDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import "ISAdMobNativeBannerDelegate.h"
#import "ISAdMobNativeView.h"

@implementation ISAdMobNativeBannerDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                  nativeTemplate:(ISAdMobNativeBannerTemplate*)nativeTemplate
                        delegate:(id<ISBannerAdapterDelegate>)delegate {
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
            
            ISAdMobNativeView *nativeView = [[ISAdMobNativeView alloc] initWithTemplate:self.nativeTemplate
                                                                               nativeAd:nativeAd];
            nativeAd.delegate = self;
            [self.delegate adapterBannerDidLoad:nativeView];
        });
}

/// Called when adLoader fails to load an ad.
- (void)adLoader:(nonnull GADAdLoader *)adLoader
    didFailToReceiveAdWithError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = (error.code == GADErrorNoFill || error.code == GADErrorMediationNoFill)? [ISError createError:ERROR_BN_LOAD_NO_FILL
                                                                                                            withMessage:@"AdMob no fill"] : error;

    [self.delegate adapterBannerDidFailToLoadWithError:smashError];
}

/// Called when an impression is recorded for an ad.
- (void)nativeAdDidRecordImpression:(GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidShow];
}

/// Called when a click is recorded for an ad.
- (void)nativeAdDidRecordClick:(GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidClick];
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
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerWillPresentScreen];
}

/// Called after dismissing a full screen view. Use this opportunity to restart anything you may
/// have stopped as part of nativeAdWillPresentScreen:.
- (void)nativeAdDidDismissScreen:(GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidDismissScreen];
}

@end
