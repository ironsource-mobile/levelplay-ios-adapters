//
//  ISYandexRewardedVideoAdDelegate.m
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexRewardedVideoAdapter.h"
#import "ISYandexRewardedVideoAdDelegate.h"

@implementation ISYandexRewardedVideoAdDelegate

- (instancetype)initWithAdapter:(ISYandexRewardedVideoAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Notifies that the ad loaded successfully.
/// @param adLoader A reference to an object of the RewardedAdLoader class that invoked the method.
/// @param rewardedAd A reference to an object of the RewardedAd class that invoked the method.
- (void)rewardedAdLoader:(YMARewardedAdLoader * _Nonnull)adLoader
                 didLoad:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);

    [self.adapter onAdUnitAvailabilityChangeWithAdUnitId:self.adUnitId
                                            availability:YES
                                         rewardedVideoAd:rewardedAd];
    
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];

}

/// Notifies that the ad failed to load.
/// @param adLoader A reference to an object of the RewardedAdLoader class that invoked the method.
/// @param error Information about the error (for details, see AdErrorCode).
- (void)rewardedAdLoader:(YMARewardedAdLoader * _Nonnull)adLoader
  didFailToLoadWithError:(YMAAdRequestError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error.error);
    NSError *smashError = error.error.code == YMAAdErrorCodeNoFill ? [ISError createError:ERROR_RV_LOAD_NO_FILL
                                                                              withMessage:@"Yandex no fill"] : error.error;
    
    [self.adapter onAdUnitAvailabilityChangeWithAdUnitId:self.adUnitId
                                            availability:NO
                                         rewardedVideoAd:nil];
    
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
}

/// Called after the rewarded ad shows.
/// @param rewardedAd A reference to an object of the RewardedAd class that invoked the method.
- (void)rewardedAdDidShow:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// Notifies that the ad can’t be displayed.
/// @param rewardedAd A reference to an object of the RewardedAd class that invoked the method.
/// @param error Information about the error (for details, see AdErrorCode).
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
didFailToShowWithError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

/// Notifies delegate when an impression was tracked.
/// @param rewardedAd A reference to an object of the RewardedAd class that invoked the method.
/// @param impressionData Ad impression-level revenue data.
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
didTrackImpressionWith:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}


/// Notifies that the user has clicked on the ad.
/// @param rewardedAd A reference to an object of the RewardedAd class that invoked the method.
- (void)rewardedAdDidClick:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClick];
}

/// Notifies that rewarded ad has rewarded the user.
/// @param rewardedAd A reference to an object of the RewardedAd class that invoked the method.
/// @param reward Reward given to the user.
- (void)rewardedAd:(YMARewardedAd * _Nonnull)rewardedAd
         didReward:(id <YMAReward> _Nonnull)reward {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidEnd];
    [self.delegate adapterRewardedVideoDidReceiveReward];
}


/// Called after dismissing the rewarded ad.
/// @param rewardedAd A reference to an object of the RewardedAd class that invoked the method.
- (void)rewardedAdDidDismiss:(YMARewardedAd * _Nonnull)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClose];
}

@end
