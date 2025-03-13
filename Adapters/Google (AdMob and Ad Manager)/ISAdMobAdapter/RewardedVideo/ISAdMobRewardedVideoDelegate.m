//
//  ISAdMobRewardedVideoDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import "ISAdMobRewardedVideoDelegate.h"

@implementation ISAdMobRewardedVideoDelegate

- (instancetype)initWithAdapter:(ISAdMobRewardedVideoAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _adapter = adapter;
        _adUnitId = adUnitId;
        _delegate = delegate;
        
        ISAdMobRewardedVideoDelegate * __weak weakSelf = self;
        _completionBlock = ^(GADRewardedAd *rewardedAd, NSError *error) {
            __typeof__(self) strongSelf = weakSelf;
            if (error) {
                [strongSelf adDidFailToLoadWithError:error];
            } else {
                [strongSelf adDidLoadWithAd:rewardedAd];
            }
        };
    }
    return self;
}

- (void)adDidLoadWithAd:(GADRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);

    [self.adapter onAdUnitAvailabilityChangeWithAdUnitId:self.adUnitId
                                            availability:YES
                                              rewardedAd:rewardedAd];
    
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)adDidFailToLoadWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = (error.code == GADErrorNoFill) ? [ISError createError:ERROR_RV_LOAD_NO_FILL
                                                                                                             withMessage:@"AdMob no fill"] : error;

    [self.adapter onAdUnitAvailabilityChangeWithAdUnitId:self.adUnitId
                                            availability:NO
                                              rewardedAd:nil];
    
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
}

/// Tells the delegate that the ad presented full screen content.
- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

/// Tells the delegate that an impression has been recorded for the ad.
- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidOpen];
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClick];
}

/// Tells the delegate that the ad will dismiss full screen content.
- (void)adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClose];
}

@end
