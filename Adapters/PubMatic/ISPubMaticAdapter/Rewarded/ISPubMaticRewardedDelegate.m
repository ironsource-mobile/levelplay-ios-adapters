//
//  ISPubMaticRewardedDelegate.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISPubMaticRewardedDelegate.h"
#import "ISPubMaticConstants.h"

@implementation ISPubMaticRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)rewardedAdDidReceiveAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

- (void)rewardedAd:(POBRewardedAd *)rewardedAd didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);
    ISAdapterErrorType errorType = (error.code == POBErrorNoAds) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)rewardedAdDidRecordImpression:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)rewardedAd:(POBRewardedAd *)rewardedAd didFailToShowAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)rewardedAdDidClickAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)rewardedAd:(POBRewardedAd *)rewardedAd shouldReward:(POBReward *)reward {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

- (void)rewardedAdDidDismissAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)rewardedAdWillPresentAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardedAdDidPresentAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardedAdWillLeaveApplication:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
