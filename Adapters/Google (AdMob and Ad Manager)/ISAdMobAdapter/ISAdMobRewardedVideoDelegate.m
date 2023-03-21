//
//  ISAdMobRewardedVideoDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#include <ISAdMobRewardedVideoDelegate.h>

@implementation ISAdMobRewardedVideoDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISAdMobRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Tells the delegate that the ad presented full screen content.
- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
}

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    [_delegate onRewardedVideoShowFail:_adUnitId withError:error];
}

/// Tells the delegate that an impression has been recorded for the ad.
- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad {
    [_delegate onRewardedVideoDidOpen:_adUnitId];
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    [_delegate onRewardedVideoDidClick:_adUnitId];
}

/// Tells the delegate that the ad will dismiss full screen content.
- (void)adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    [_delegate onRewardedVideoDidClose:_adUnitId];
}

@end
