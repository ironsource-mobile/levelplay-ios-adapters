//
//  ISMolocoRewardedVideoDelegate.m
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISMolocoRewardedVideoDelegate.h"

@implementation ISMolocoRewardedVideoDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad was successfully loaded
/// @param ad ad object that was loaded
- (void)didLoadWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

/// calls this method when ad was not loaded for some reasons
/// @param ad ad object that was loaded
/// @param error the reason of failing loading
- (void)failToLoadWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = error.code == MolocoErrorAdLoadFailed ? [ISError createError:ERROR_IS_LOAD_NO_FILL
                                                                        withMessage:@"Moloco no fill"] : error;
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
}

/// calls this method when ad was shown on screen
/// @param ad ad object that was shown
- (void)didShowWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidOpen];
}

/// calls this method when video starts. Optional, it can be not invoked.
/// @param ad object that starts video.
- (void)rewardedVideoStartedWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidStart];
    
}

/// calls this method when ad fails to show for some reasons
/// @param ad ad object that was not shown
/// @param error the reason of failing loading
- (void)failToShowWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

/// calls this method when user clicked on the ad
/// @param ad ad object that was clicked
- (void)didClickOn:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClick];
}

/// calls this method when the user gets a reward.
/// @param ad ad object that produce reward
- (void)userRewardedWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

/// calls this method when the video has completed video playback
/// @param ad ad object that was closed
- (void)rewardedVideoCompletedWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidEnd];
}

/// calls this method when ad was closed
/// @param ad ad object that video reached the end.
- (void)didHideWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClose];
}

@end
