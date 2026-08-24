//
//  ISSmaatoRewardedDelegate.m
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISSmaatoRewardedDelegate.h"
#import "ISSmaatoRewardedAdapter.h"
#import "ISSmaatoAdapter+Internal.h"

@implementation ISSmaatoRewardedDelegate

- (instancetype)initWithAdapter:(ISSmaatoRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)rewardedInterstitialDidLoad:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    NSString *creativeId = rewardedInterstitial.sci;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    [self.adapter setRewardedAd:rewardedInterstitial];

    if (creativeId.length) {
        [self.delegate adDidLoadWithExtraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)rewardedInterstitialDidFail:(SMARewardedInterstitial *_Nullable)rewardedInterstitial
                          withError:(NSError *_Nonnull)error {
    LogAdapterDelegate_Internal(logError, error);

    [self.adapter setRewardedAd:nil];

    BOOL isNoFill = error.code == kSMAErrorCodeNoAdAvailable;
    [self.delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                      errorCode:(isNoFill ? ERROR_RV_LOAD_NO_FILL : error.code)
                                   errorMessage:(isNoFill ? logNoFill : error.localizedDescription)];
}

- (void)rewardedInterstitialDidAppear:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)rewardedInterstitialDidClick:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)rewardedInterstitialDidReward:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

- (void)rewardedInterstitialDidDisappear:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)rewardedInterstitialDidTTLExpire:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logAdExpired);

    [self.adapter setRewardedAd:nil];

    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:ERROR_RV_EXPIRED_ADS
                                   errorMessage:logAdExpired];
}

- (void)rewardedInterstitialDidStart:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardedInterstitialWillAppear:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardedInterstitialWillDisappear:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardedInterstitialWillLeaveApplication:(SMARewardedInterstitial *_Nonnull)rewardedInterstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardedInterstitialOnAdFailedToLoad:(SMARewardedInterstitial *_Nullable)rewardedInterstitial
                                   withError:(NSError *_Nonnull)error {
    LogAdapterDelegate_Internal(logError, error);
}

@end
