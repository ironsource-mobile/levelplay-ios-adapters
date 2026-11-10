//
//  ISBigoInterstitialDelegate.m
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBaseInterstitial.h>
#import "ISBigoInterstitialDelegate.h"
#import "ISBigoInterstitialAdapter.h"
#import "ISBigoConstants.h"

@implementation ISBigoInterstitialDelegate

- (instancetype)initWithAdapter:(ISBigoInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - BigoInterstitialAdLoaderDelegate

- (void)onInterstitialAdLoaded:(nonnull BigoInterstitialAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.adapter storeInterstitialAd:ad];
    [self.delegate adDidLoad];
}

- (void)onInterstitialAdLoadError:(BigoAdError *)error {
    LogAdapterDelegate_Internal(logError, error);

    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.errorCode
                                   errorMessage:error.errorMsg];
}

#pragma mark - BigoAdInteractionDelegate

- (void)onAd:(BigoAd *)ad error:(BigoAdError *)error {
    LogAdapterDelegate_Internal(logError, error);

    [self.delegate adDidFailToShowWithErrorCode:error.errorCode
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

- (void)onAdOpened:(BigoAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)onAdClosed:(BigoAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
