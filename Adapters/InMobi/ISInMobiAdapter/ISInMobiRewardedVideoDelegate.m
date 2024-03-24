//
//  ISInMobiRewardedVideoDelegate.m
//  ISInMobiAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISInMobiRewardedVideoDelegate.h>

@implementation ISInMobiRewardedVideoDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISInMobiRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark IMInterstitialDelegate

/**
 Called when the IMInterstitial object loads successfully.
 @param interstitial IMInterstitial object that was loaded successfully.
 */
- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [self.delegate onRewardedVideoDidLoad:interstitial
                              placementId:self.placementId];
}

/**
 Called when the IMInterstitial object fails to load.
 @param interstitial IMInterstitial object that failed to load.
 @param error An error object containing details of the error.
 */
- (void)interstitial:(IMInterstitial *)interstitial
didFailToLoadWithError:(IMRequestStatus *)error {
    [self.delegate onRewardedVideoDidFailToLoad:interstitial
                                          error:error
                                    placementId:self.placementId];
}

/**
 Called when the IMInterstitial object logs an impression.
 @param interstitial IMInterstitial object that logged an impression.
 */
- (void)interstitialAdImpressed:(IMInterstitial *)interstitial {
    [self.delegate onRewardedVideoDidOpen:interstitial
                              placementId:self.placementId];
}

/**
 Called when the IMInterstitial object fails to load.
 @param interstitial IMInterstitial object that failed to show.
 @param error An error object containing details of the error.
 */
- (void)interstitial:(IMInterstitial *)interstitial
didFailToPresentWithError:(IMRequestStatus *)error {
    [self.delegate onRewardedVideoDidFailToShow:interstitial
                                          error:error
                                    placementId:self.placementId];
}

/**
 Called when the IMInterstitial object did dismiss.
 @param interstitial IMInterstitial object that failed to show.
 */
- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [self.delegate onRewardedVideoDidClose:interstitial
                               placementId:self.placementId];
}

/**
 Called when the IMInterstitial object was clicked.
 @param interstitial IMInterstitial object that was clicked.
 @param params additional data regarding the click.
 */
- (void)interstitial:(IMInterstitial *)interstitial
didInteractWithParams:(NSDictionary *)params {
    [self.delegate onRewardedVideoDidClick:interstitial
                                    params:params
                               placementId:self.placementId];
}

/**
 Called when user has performed the action got reward.
 @param interstitial IMInterstitial object that was rewarded.
 @param rewards data regarding the reward.
 */
- (void)interstitial:(IMInterstitial *)interstitial
rewardActionCompletedWithRewards:(NSDictionary *)rewards {
    [self.delegate onRewardedVideoDidReceiveReward:interstitial
                                           rewards:rewards
                                       placementId:self.placementId];
}

@end
