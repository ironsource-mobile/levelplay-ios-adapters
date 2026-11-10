//
//  ISAdMobNativeAdDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAdMobNativeAdDelegate.h"
#import "ISAdMobNativeAdData.h"
#import "ISAdMobNativeAdViewBinder.h"
#import "ISAdMobConstants.h"
#import <IronSource/ISNativeAdDelegate.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISAdMobNativeAdDelegate

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISNativeAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - GADNativeAdLoaderDelegate

- (void)adLoader:(nonnull GADAdLoader *)adLoader didReceiveNativeAd:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    ISAdapterNativeAdData *adData = [[ISAdMobNativeAdData alloc] initWithNativeAd:nativeAd];
    ISAdapterNativeAdViewBinder *binder = [[ISAdMobNativeAdViewBinder alloc] initWithNativeAd:nativeAd];

    nativeAd.delegate = self;
    nativeAd.rootViewController = self.viewController;

    [self.delegate adDidLoadWithAdData:adData
                          adViewBinder:binder];
}

- (void)adLoader:(nonnull GADAdLoader *)adLoader didFailToReceiveAdWithError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);

    ISAdapterErrorType errorType = (error.code == GADErrorNoFill) ?
        ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

#pragma mark - GADNativeAdDelegate

- (void)nativeAdWillPresentScreen:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)nativeAdDidRecordImpression:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)nativeAdDidRecordClick:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)nativeAdDidDismissScreen:(nonnull GADNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
