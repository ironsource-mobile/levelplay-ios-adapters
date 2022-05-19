//
//  ISMyTargetRewardedVideoListener.m
//  ISMyTargetAdapter
//
//  Created by Hadar Pur on 14/07/2020.
//

#import "ISMyTargetRewardedVideoListener.h"

@implementation ISMyTargetRewardedVideoListener

- (instancetype)initWithDelegate:(id<ISMyTargetRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/**
 *  Called when the ad is successfully load , and is ready to be displayed
 */
- (void)onLoadWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    [_delegate onRewardedVideoLoadSuccess:rewardedAd];
}

/**
 *  Called when there was an error loading the ad.
 *  @param reason       - reasont that describes the exact error encountered when loading the ad.
 */
- (void)onNoAdWithReason:(NSString *)reason rewardedAd:(MTRGRewardedAd *)rewardedAd {
    [_delegate onRewardedVideoLoadFailWithReason:reason rewardedVideoAd:rewardedAd];
}

/**
 *  Called when the ad is clicked
 */
- (void)onClickWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    [_delegate onRewardedVideoClicked:rewardedAd];
}

/**
 *  Called when the ad display success
 */
- (void)onDisplayWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    [_delegate onRewardedVideoDisplay:rewardedAd];
}


/**
 *  Called when the ad  did closed
 */
- (void)onCloseWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    [_delegate onRewardedVideoClosed:rewardedAd];
}

/**
 *  Called when the ad  did complited
 */
- (void)onReward:(MTRGReward *)reward rewardedAd:(MTRGRewardedAd *)rewardedAd {
    [_delegate onRewardedVideoCompleted:rewardedAd];
}

@end

