//
//  ISAdMobInterstitialDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAdMobInterstitialDelegate.h"
#import "ISAdMobConstants.h"

@implementation ISAdMobInterstitialDelegate

- (instancetype)initWithAdapter:(ISAdMobInterstitialAdapter *)adapter
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

/// Tells the delegate that the ad presented full screen content.
- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

/// Tells the delegate that an impression has been recorded for the ad.
- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClick];
}

/// Tells the delegate that the ad will dismiss full screen content.
- (void)adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClose];
}

@end
