//
//  ISVungleRewardedVideoDelegate.m
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISVungleRewardedVideoDelegate.h"
#import "ISVungleConstant.h"

@implementation ISVungleRewardedVideoDelegate

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

- (void)rewardedAdDidLoad:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)rewardedAdDidFailToLoad:(VungleRewarded * _Nonnull)rewarded
                      withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);
    
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    NSInteger errorCode = (error.code == VungleErrorAdNoFill) ? ERROR_RV_LOAD_NO_FILL : error.code;
    NSError *rewarededVideoError = [NSError errorWithDomain:kAdapterName
                                                       code:errorCode
                                                   userInfo:@{NSLocalizedDescriptionKey:error.description}];
    
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:rewarededVideoError];
}

- (void)rewardedAdDidTrackImpression:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

- (void)rewardedAdDidFailToPresent:(VungleRewarded * _Nonnull)rewarded
                         withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

- (void)rewardedAdDidClick:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidClick];
}

- (void)rewardedAdDidRewardUser:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

- (void)rewardedAdDidClose:(VungleRewarded * _Nonnull)rewarded {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidEnd];
    [self.delegate adapterRewardedVideoDidClose];
}

@end
