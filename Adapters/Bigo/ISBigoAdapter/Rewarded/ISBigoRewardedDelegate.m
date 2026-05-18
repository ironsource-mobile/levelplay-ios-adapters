//
//  ISBigoRewardedDelegate.m
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import "ISBigoRewardedDelegate.h"
#import "ISBigoRewardedAdapter.h"
#import "ISBigoConstants.h"

@implementation ISBigoRewardedDelegate

- (instancetype)initWithAdapter:(ISBigoRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - BigoRewardVideoAdLoaderDelegate

- (void)onRewardVideoAdLoaded:(nonnull BigoRewardVideoAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.adapter storeRewardedAd:ad];
    [self.delegate adDidLoad];
}

- (void)onRewardVideoAdLoadError:(BigoAdError *)error {
    LogAdapterDelegate_Internal(logError, error);

    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.errorCode
                                   errorMessage:error.errorMsg];
}

#pragma mark - BigoRewardVideoAdInteractionDelegate

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

- (void)onAdRewarded:(BigoRewardVideoAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

@end
