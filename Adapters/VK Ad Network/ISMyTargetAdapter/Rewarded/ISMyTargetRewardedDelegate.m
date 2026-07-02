//
//  ISMyTargetRewardedDelegate.m
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MyTargetSDK/MyTargetSDK.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISMyTargetRewardedDelegate.h"
#import "ISMyTargetRewardedAdapter.h"
#import "ISMyTargetConstants.h"

@implementation ISMyTargetRewardedDelegate

- (instancetype)initWithAdapter:(ISMyTargetRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - MTRGRewardedAdDelegate

- (void)onLoadWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.adapter setRewardedAdAvailability:YES];
    [self.delegate adDidLoad];
}

- (void)onLoadFailedWithError:(NSError *)error
                   rewardedAd:(MTRGRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logError, error);
    [self.adapter setRewardedAdAvailability:NO];
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)onClickWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)onDisplayWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)onCloseWithRewardedAd:(MTRGRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)onReward:(MTRGReward *)reward rewardedAd:(MTRGRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

@end
