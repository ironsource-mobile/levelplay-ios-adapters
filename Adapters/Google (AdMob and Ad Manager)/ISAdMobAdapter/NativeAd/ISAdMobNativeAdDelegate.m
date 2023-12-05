//
//  ISAdMobNativeAdDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <ISAdMobNativeAdDelegate.h>
#import <ISAdMobNativeAdData.h>
#import <ISAdMobNativeAdViewBinder.h>

@implementation ISAdMobNativeAdDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                  viewController:(UIViewController *)viewController
                     andDelegate:(id<ISNativeAdAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Called when a native ad is received.
- (void)adLoader:(nonnull GADAdLoader *)adLoader didReceiveNativeAd:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    
    ISAdapterNativeAdData *adData = [[ISAdMobNativeAdData alloc] initWithNativeAd:nativeAd];
    ISAdapterNativeAdViewBinder *binder = [[ISAdMobNativeAdViewBinder alloc] initWithNativeAd:nativeAd];
    
    nativeAd.delegate = self;
    nativeAd.rootViewController = self.viewController;
    
    [self.delegate adapterNativeAdDidLoadWithAdData:adData
                                       adViewBinder:binder];
}

/// Called when adLoader fails to load an ad.
- (void)adLoader:(nonnull GADAdLoader *)adLoader didFailToReceiveAdWithError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = (error.code == GADErrorNoFill || error.code == GADErrorMediationNoFill) ? [ISError createError:ERROR_NT_LOAD_NO_FILL
                                                                                                             withMessage:@"AdMob no fill"] : error;
    [self.delegate adapterNativeAdDidFailToLoadWithError:smashError];
}

/// Called before presenting the user a full screen view in response to an ad action. Use this
/// opportunity to stop animations, time sensitive interactions, etc.
///
/// Normally the user looks at the ad, dismisses it, and control returns to your application with
/// the nativeAdDidDismissScreen: message. However, if the user hits the Home button or clicks on an
/// App Store link, your application will be backgrounded. The next method called will be the
/// applicationWillResignActive: of your UIApplicationDelegate object.
- (void)nativeAdWillPresentScreen:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// Called when an impression is recorded for an ad.
- (void)nativeAdDidRecordImpression:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterNativeAdDidShow];
}

/// Called when a click is recorded for an ad.
- (void)nativeAdDidRecordClick:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterNativeAdDidClick];
}

/// Called after dismissing a full screen view. Use this opportunity to restart anything you may
/// have stopped as part of nativeAdWillPresentScreen:.
- (void)nativeAdDidDismissScreen:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

@end
