//
//  ISVungleRewardedVideoAdapterRouter.m
//  ISVungleAdapter
//
//  Copyright © 2020 ironSource. All rights reserved.
//

#import "ISVungleRewardedVideoAdapterRouter.h"
#import "ISVungleAdapter.h"

@interface ISVungleRewardedVideoAdapterRouter()

@property (nonatomic, strong, nullable) NSString *bidPayload;

@end

@implementation ISVungleRewardedVideoAdapterRouter

- (instancetype)initWithPlacementID:(NSString *)placementID
                      parentAdapter:(ISVungleAdapter *)parentAdapter
                           delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    if (self = [super init]) {
        _placementID = placementID;
        _parentAdapter = parentAdapter;
        _delegate = delegate;
        _bidPayload = nil;
    }

    return self;
}

- (void)loadRewardedVideoAd {
    self.rewardedVideoAd = [[VungleRewarded alloc] initWithPlacementId:self.placementID];
    self.rewardedVideoAd.delegate = self;

    if ([self.rewardedVideoAd canPlayAd]) {
        LogInternal_Internal(@"Rewarded ad: %@ is loaded", self.placementID);
        [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
        return;
    }

    [self.rewardedVideoAd load:self.bidPayload];
}

- (void)playRewardedVideoAdWithViewController:(UIViewController *)viewController {
    [self.rewardedVideoAd presentWith:viewController];
}

- (void)setBidPayload:(NSString * _Nullable)bidPayload {
    self.bidPayload = bidPayload;
}

- (void)rewardedVideoInitSuccess {
    [self.delegate adapterRewardedVideoInitSuccess];
}

- (void)rewardedVideoInitFailed:(NSError *)error {
    [self.delegate adapterRewardedVideoInitFailed:error];
}

- (void)rewardedVideoHasChangedAvailability:(BOOL)available {
    [self.delegate adapterRewardedVideoHasChangedAvailability:available];
}

#pragma mark - VungleRewardedDelegate

- (void)rewardedAdDidLoad:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
    if (![rewarded canPlayAd]) {
        // When Rewarded Video is loaded the canPlayAd should also return YES
        // If for some reason that is not the case we can also catch it on the Show method
        LogAdapterDelegate_Internal(@"Vungle Ad is loaded but not ready to be shown");
    }

    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)rewardedAdDidFailToLoad:(VungleRewarded * _Nonnull)rewarded withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", rewarded.placementId, error);
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:error];
}

- (void)rewardedAdDidTrackImpression:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

- (void)rewardedAdDidFailToPresent:(VungleRewarded * _Nonnull)rewarded withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", rewarded.placementId, error);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

- (void)rewardedAdDidClose:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
    [self.delegate adapterRewardedVideoDidEnd];
    [self.delegate adapterRewardedVideoDidClose];
}

- (void)rewardedAdDidClick:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
    [self.delegate adapterRewardedVideoDidClick];
}

- (void)rewardedAdDidRewardUser:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

- (void)rewardedAdWillPresent:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
}

- (void)rewardedAdDidPresent:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
}

- (void)rewardedAdWillClose:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
}

- (void)rewardedAdWillLeaveApplication:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementID = %@", rewarded.placementId);
}

@end
