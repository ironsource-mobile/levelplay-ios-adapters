//
//  ISYandexRewardedDelegate.m
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YandexMobileAds;
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISYandexRewardedDelegate.h"
#import "ISYandexRewardedAdapter.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexConstants.h"

@implementation ISYandexRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// Called after the rewarded ad shows.
- (void)rewardedAdDidShow:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

/// Notifies that the ad can't be displayed.
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
didFailToShowWithError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// Notifies delegate when an impression was tracked.
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
didTrackImpressionWithData:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Notifies that the user has clicked on the ad.
- (void)rewardedAdDidClick:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Notifies that rewarded ad has rewarded the user.
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
         didReward:(id <YMAReward> _Nonnull)reward {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

/// Called after dismissing the rewarded ad.
- (void)rewardedAdDidDismiss:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
