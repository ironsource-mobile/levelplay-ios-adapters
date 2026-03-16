//
//  ISVoodooInterstitialDelegate.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVoodooInterstitialDelegate.h"
#import "ISVoodooConstants.h"

@implementation ISVoodooInterstitialDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Interstitial Delegate

- (void)handleOnLoad:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    if (error) {
        [self.delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    [self.delegate adapterInterstitialDidLoad];
}

- (void)didPresentFullscreenAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
}


- (void)didFailToPresentFullscreenAdWithError:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

- (void)didRecordAdImpression {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

- (void)didRecordAdClick {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidClick];
}

- (void)didDismissFullscreenAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidClose];
}

- (void)onAdRewarded {
    // not relevant to interstitial
}

@end
