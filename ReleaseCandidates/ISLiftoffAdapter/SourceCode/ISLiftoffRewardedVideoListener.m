//
//  ISLiftoffRewardedVideoListener.m
//  ISLiftoffAdapter
//
//  Created by Roi Eshel on 14/09/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISLiftoffRewardedVideoListener.h"

@implementation ISLiftoffRewardedVideoListener

- (instancetype)initWithDelegate:(id<ISLiftoffRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

// Called when the rewarded ad request is successfully filled.
- (void)loInterstitialDidLoad:(LOInterstitial *)rewardedAd {
    [_delegate onRewardedVideoLoadSuccess:rewardedAd];
}

// Called when the rewarded ad request cannot be filled.
- (void)loInterstitialDidFailToLoad:(LOInterstitial *)rewardedAd {
    [_delegate onRewardedVideoLoadFail:rewardedAd];
}


// Called when the rewarded ad becomes visible to the user.
- (void)loInterstitialImpressionDidTrigger:(LOInterstitial *)rewardedAd {
    [_delegate onRewardedVideoDidOpen:rewardedAd];
}

// Called before the rewarded ad view controller is presented.
- (void)loInterstitialWillShow:(LOInterstitial *)rewardedAd {
    
}

// Called after the rewarded ad view controller is presented.
- (void)loInterstitialDidShow:(LOInterstitial *)rewardedAd {
    [_delegate onRewardedVideoDidShow:rewardedAd];
}

// Called when the user will be directed to an external destination.
- (void)loInterstitialClickDidTrigger:(LOInterstitial *)rewardedAd {
    [_delegate onRewardedVideoDidClick:rewardedAd];
}

// Called when the user is about to leave the application
- (void)loInterstitialWillLeaveApplication:(LOInterstitial *)rewardedAd {
}


// Called before the rewarded ad view controller is hidden.
- (void)loInterstitialWillHide:(LOInterstitial *)rewardedAd {
    
}

// Called after the rewarded ad view controller is hidden.
- (void)loInterstitialDidHide:(LOInterstitial *)rewardedAd {
    [_delegate onRewardedVideoDidClose:rewardedAd];
}

// Called when the user has earned a reward by watching a rewarded ad.
- (void)loInterstitialWillRewardUser:(LOInterstitial *)rewardedAd {
    [_delegate onRewardedVideoDidReceiveReward:rewardedAd];
}

// Called when the rewarded ad fails during display.
- (void)loInterstitialDidFailToDisplay:(LOInterstitial * _Nonnull)rewardedAd {
    [_delegate onRewardedVideoShowFail:rewardedAd];
}

@end

