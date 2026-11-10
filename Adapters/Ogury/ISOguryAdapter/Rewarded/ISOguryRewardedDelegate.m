//
//  ISOguryRewardedDelegate.m
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OguryAds/OguryAds.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISOguryRewardedDelegate.h"
#import "ISOguryConstants.h"

@implementation ISOguryRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - OguryRewardedAdDelegate

- (void)rewardedAdDidLoad:(OguryRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

- (void)rewardedAd:(OguryRewardedAd *)rewardedAd didFailWithError:(OguryAdError *)error {
    LogAdapterDelegate_Internal(logError, error);

    if (error.type == OguryAdErrorTypeLoad) {
        ISAdapterErrorType errorType = (error.code == OguryLoadErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
        [self.delegate adDidFailToLoadWithErrorType:errorType
                                          errorCode:error.code
                                       errorMessage:error.localizedDescription];
    } else {
        [self.delegate adDidFailToShowWithErrorCode:error.code
                                       errorMessage:error.localizedDescription];
    }
}

- (void)rewardedAdDidTriggerImpression:(OguryRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)rewardedAdDidClick:(OguryRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)rewardedAdDidClose:(OguryRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)rewardedAd:(OguryRewardedAd *)rewardedAd didReceiveReward:(OguryReward *)reward {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

@end
