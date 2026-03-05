//
//  ISYandexRewardedDelegate.m
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISYandexRewardedDelegate.h"
#import "ISYandexRewardedAdapter.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexConstants.h"

@implementation ISYandexRewardedDelegate

- (instancetype)initWithAdapter:(ISYandexRewardedAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Notifies that the ad loaded successfully.
- (void)rewardedAdLoader:(YMARewardedAdLoader * _Nonnull)adLoader
                 didLoad:(YMARewardedAd * _Nonnull)rewardedAd {
    [self.adapter setAdAvailability:YES
                     withRewardedAd:rewardedAd];

    // Extract creative IDs and pass as extra data if available
    NSString *creativeId = [ISYandexAdapter buildCreativeIdStringFromCreatives:rewardedAd.adInfo.creatives];
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithExtraData:extraData];
    } else {
        [self.delegate adDidLoad];
    }
}

/// Notifies that the ad failed to load.
- (void)rewardedAdLoader:(YMARewardedAdLoader * _Nonnull)adLoader
  didFailToLoadWithError:(YMAAdRequestError * _Nonnull)error {
    LogAdapterDelegate_Internal(logCallbackFailed, self.adUnitId, error.error.localizedDescription);

    ISAdapterErrorType errorType = (error.error.code == yandexNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.adapter setAdAvailability:NO
                     withRewardedAd:nil];

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.error.code
                                   errorMessage:error.error.localizedDescription];
}

/// Called after the rewarded ad shows.
- (void)rewardedAdDidShow:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

/// Notifies that the ad can't be displayed.
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
didFailToShowWithError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logCallbackFailed, self.adUnitId, error.localizedDescription);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// Notifies delegate when an impression was tracked.
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
didTrackImpressionWith:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
    [self.delegate adDidStart];
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
    [self.delegate adDidEnd];
    [self.delegate adRewarded];
}

/// Called after dismissing the rewarded ad.
- (void)rewardedAdDidDismiss:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
