//
//  ISPangleRewardedVideoDelegate.m
//  ISPangleAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISPangleRewardedVideoDelegate.h>

@implementation ISPangleRewardedVideoDelegate

- (instancetype)initWithSlotId:(NSString *)slotId
                   andDelegate:(id<ISPangleRewardedVideoDelegateWrapper>)delegate {
    
    self = [self init];
    
    if (self) {
        _slotId = slotId;
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark PAGRewardedVideoAdDelegate Delegates

/// This method is invoked when the ad is displayed, covering the device's screen.
- (void)adDidShow:(id<PAGAdProtocol>)ad {
    [_delegate onRewardedVideoDidOpen:_slotId];
}

/// This method is invoked when the ad is clicked by the user.
- (void)adDidClick:(id<PAGAdProtocol>)ad {
    [_delegate onRewardedVideoDidClick:_slotId];
}

/// Tells the delegate that the user has earned the reward.
/// @param rewardedAd rewarded ad instance
/// @param rewardModel user's reward info
- (void)rewardedAd:(PAGRewardedAd *)rewardedAd userDidEarnReward:(PAGRewardModel *)rewardModel {
    [_delegate onRewardedVideoDidReceiveReward:_slotId];
    [_delegate onRewardedVideoDidEnd:_slotId];
}

/// This method is invoked when the ad disappears.
- (void)adDidDismiss:(id<PAGAdProtocol>)ad {
    [_delegate onRewardedVideoDidClose:_slotId];
}

@end
