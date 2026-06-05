//
//  ISPangleRewardedDelegate.m
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import "ISPangleRewardedDelegate.h"
#import "ISPangleConstants.h"

@implementation ISPangleRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark PAGRewardedAdDelegate Delegates

/// This method is invoked when the ad is displayed, covering the device's screen.
- (void)adDidShow:(id<PAGAdProtocol>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// This method is invoked when the ad is clicked by the user.
- (void)adDidClick:(id<PAGAdProtocol>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Tells the delegate that the user has earned the reward.
/// @param rewardedAd rewarded ad instance
/// @param rewardModel user's reward info
- (void)rewardedAd:(PAGRewardedAd *)rewardedAd userDidEarnReward:(PAGRewardModel *)rewardModel {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

/// This method is invoked when the ad disappears.
- (void)adDidDismiss:(id<PAGAdProtocol>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
