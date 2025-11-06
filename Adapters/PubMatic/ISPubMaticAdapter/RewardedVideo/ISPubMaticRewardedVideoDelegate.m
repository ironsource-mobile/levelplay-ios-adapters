//
//  ISPubMaticRewardedVideoDelegate.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticRewardedVideoDelegate.h"

@implementation ISPubMaticRewardedVideoDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                        andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/*!
 @abstract Notifies the delegate that an rewarded ad has been received successfully.
 @param rewardedAd The POBRewardedAd instance sending the message.
 */
-(void)rewardedAdDidReceiveAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

/*!
 @abstract Notifies the delegate of an error encountered while loading an ad.
 @param rewardedAd The POBRewardedAd instance sending the message.
 @param error The error encountered while attempting to receive or render the ad.
 */
-(void)rewardedAd:(POBRewardedAd *)rewardedAd didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@, error = %@", self.adUnitId, error);
    NSInteger errorCode = (error.code == POBErrorNoAds) ? ERROR_RV_LOAD_NO_FILL : error.code;
    NSError *loadError = [NSError errorWithDomain:kAdapterName
                                             code:errorCode
                                         userInfo:@{NSLocalizedDescriptionKey:error.description}];
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:loadError];
}

/*!
 @abstract Notifies the delegate that the rewarded ad will be presented as a modal on top of the current view controller.
 @param rewardedAd The POBRewardedAd instance sending the message.
 */
-(void)rewardedAdWillPresentAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/*!
 @abstract Notifies the delegate that the rewarded ad is presented as a modal on top of the current view controller.
 @param rewardedAd The POBRewardedAd instance sending the message.
 */
-(void)rewardedAdDidPresentAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/**
 * @abstract Notifies the delegate that the rewarded ad has recorded the impression.
 *
 * @param rewardedAd The POBRewardedAd instance sending the message.
 */
- (void)rewardedAdDidRecordImpression:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

/*!
 @abstract Notifies the delegate of an error encountered while showing an ad.
 @param rewardedAd The POBRewardedAd instance sending the message.
 @param error The error encountered while attempting to render the ad.
 */
-(void)rewardedAd:(POBRewardedAd *)rewardedAd didFailToShowAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@, error = %@", self.adUnitId, error);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

/*!
 @abstract Notifies the delegate of ad click
 @param rewardedAd The POBRewardedAd instance sending the message.
 */
-(void)rewardedAdDidClickAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClick];
}

/*!
 @abstract Notifies the delegate that a user interaction will open another app (e.g. App Store), leaving the current app. To handle user clicks that open the
 landing page URL in the internal browser, use 'RewardedAdDidClickAd:'
 instead.
 @param rewardedAd The POBRewardedAd instance sending the message.
 */
-(void)rewardedAdWillLeaveApplication:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/*!
 @abstract Notifies the delegate that a user will be rewarded once the ad is completely viewed.
 @param rewardedAd The POBRewardedAd instance sending the message.
 @param reward The POBReward instance to reward.
 */
-(void)rewardedAd:(POBRewardedAd *)rewardedAd shouldReward:(POBReward *)reward {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

/*!
 @abstract Notifies the delegate that the rewarded ad has been animated off the screen.
 @param rewardedAd The POBRewardedAd instance sending the message.
 */
-(void)rewardedAdDidDismissAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidEnd];
    [self.delegate adapterRewardedVideoDidClose];
}

/*!
 @abstract Notifies the delegate of an ad expiration. After this callback, this 'POBRewardedAd' instance is marked as invalid & will not be shown.
 @param rewardedAd The POBRewardedAd instance sending the message.
 */
-(void)rewardedAdDidExpireAd:(POBRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    NSError *smashError = [ISError createError:ERROR_RV_EXPIRED_ADS
                              withMessage:@"ads are expired"];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
}

@end
