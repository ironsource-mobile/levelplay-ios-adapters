//
//  ISVoodooRewardedVideoDelegate.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVoodooRewardedVideoDelegate.h"
#import "ISVoodooConstants.h"

@implementation ISVoodooRewardedVideoDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Rewarded Video Delegate

- (void)handleOnLoad:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    if (error) {
        [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
        [self.delegate adapterRewardedVideoDidFailToLoadWithError:error];
        return;
    }
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)didPresentFullscreenAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
}

- (void)didFailToPresentFullscreenAdWithError:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

- (void)didRecordAdImpression {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

- (void)didRecordAdClick {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidClick];
}

- (void)onAdRewarded {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

- (void)didDismissFullscreenAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidClose];
}

@end
