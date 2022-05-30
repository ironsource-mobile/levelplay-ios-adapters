//
//  ISAdMobRewardedVideoListener.m
//  ISAdMobAdapter
//
//  Created by maoz.elbaz on 24/02/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#include "ISAdMobRewardedVideoListener.h"

@implementation ISAdMobRewardedVideoListener

- (instancetype)initWithAdUnitId:(NSString *)adUnitId andDelegate:(id<ISAdMobRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Tells the delegate that the ad presented full screen content.
- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    [_delegate onRewardedVideoDidOpen:_adUnitId];
}


/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad
didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    [_delegate onRewardedVideoShowFail:_adUnitId withError:error];
}

/// Tells the delegate that an impression has been recorded for the ad.
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad {
    [_delegate onRewardedVideoDidClick:_adUnitId];
}

/// Tells the delegate that the ad will dismiss full screen content.
- (void)adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    [_delegate onRewardedVideoDidClose:_adUnitId];
}




@end
