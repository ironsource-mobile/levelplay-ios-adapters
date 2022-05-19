//
//  ISInMobiRvListener.m
//  ISInMobiAdapter
//
//  Created by Roni Schwartz on 27/11/2018.
//  Copyright © 2018 supersonic. All rights reserved.
//

#import "ISInMobiRewardedVideoListener.h"

@implementation ISInMobiRewardedVideoListener


- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISInMobiRewardedVideoListenerDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}


- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [_delegate rewardedVideoDidFinishLoading:interstitial placementId:_placementId];
    
}
- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error {
    [_delegate rewardedVideo:interstitial didFailToLoadWithError:error placementId:_placementId];
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
    [_delegate rewardedVideoDidPresent:interstitial placementId:_placementId];
    
}
- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error {
    [_delegate rewardedVideo:interstitial didFailToPresentWithError:error placementId:_placementId];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [_delegate rewardedVideoDidDismiss:interstitial placementId:_placementId];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params {
    [_delegate rewardedVideo:interstitial didInteractWithParams:params placementId:_placementId];
    
}
- (void)interstitial:(IMInterstitial *)interstitial rewardActionCompletedWithRewards:(NSDictionary *)rewards {
    [_delegate rewardedVideo:interstitial rewardActionCompletedWithRewards:rewards placementId:_placementId];
    
}
- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
}
- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
}
- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
}
@end
