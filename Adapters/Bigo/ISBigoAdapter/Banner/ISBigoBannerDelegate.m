//
//  ISBigoBannerDelegate.m
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBaseBanner.h>
#import "ISBigoBannerDelegate.h"
#import "ISBigoBannerAdapter.h"
#import "ISBigoConstants.h"

@implementation ISBigoBannerDelegate

- (instancetype)initWithAdapter:(ISBigoBannerAdapter *)adapter
                       delegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - BigoBannerAdLoaderDelegate

- (void)onBannerAdLoaded:(nonnull BigoBannerAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.adapter storeBannerAd:ad];
    [self.delegate adDidLoadWithView:ad.adView];
}

- (void)onBannerAdLoadError:(BigoAdError *)error {
    LogAdapterDelegate_Internal(logError, error);

    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.errorCode
                                   errorMessage:error.errorMsg];
}

#pragma mark - BigoAdInteractionDelegate

- (void)onAd:(BigoAd *)ad error:(BigoAdError *)error {
    LogAdapterDelegate_Internal(logError, error);

    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.errorCode
                                   errorMessage:error.errorMsg];
}

- (void)onAdImpression:(BigoAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)onAdClicked:(BigoAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

@end
