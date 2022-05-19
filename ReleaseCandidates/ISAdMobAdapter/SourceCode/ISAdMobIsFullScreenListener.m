//
//  ISAdMobIsFullScreenListener.m
//  ISAdMobAdapter
//
//  Created by maoz.elbaz on 24/02/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#include "ISAdMobIsFullScreenListener.h"

@implementation ISAdMobIsFullScreenListener

- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISAdMobIsFullScreenDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}


/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad
didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    [_delegate isAdDidFailToPresentFullScreenContentWithError:error ForPlacementId:_placementId];
}

/// Tells the delegate that the ad presented full screen content.
- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    [_delegate isAdWillPresentFullScreenContentForPlacementId:_placementId];
}

/// Tells the delegate that the ad will dismiss full screen content.
- (void)adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    [_delegate isAdWillDismissFullScreenContentForPlacementId:_placementId];
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
     [_delegate isAdDidDismissFullScreenContentForPlacementId:_placementId];

}

/// Tells the delegate that an impression has been recorded for the ad.
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
    [_delegate isAdDidRecordImpressionForPlacementId:_placementId];
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad {
    [_delegate isAdDidRecordClickForPlacementId:_placementId];
}

@end
