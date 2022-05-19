//
//  ISInMobiIsListener.m
//  ISInMobiAdapter
//
//  Created by Roni Schwartz on 27/11/2018.
//  Copyright © 2018 supersonic. All rights reserved.
//

#import "ISInMobiInterstitialListener.h"

@implementation ISInMobiInterstitialListener

- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISInMobiInterstitialListenerDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [_delegate interstitialDidFinishLoading:(IMInterstitial *)interstitial placementId:_placementId];
    
}
- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error {
    [_delegate interstitial:interstitial didFailToLoadWithError:error placementId:_placementId];
}
- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
    [_delegate interstitialDidPresent:interstitial placementId:_placementId];
    
}
- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error {
    [_delegate interstitial:interstitial didFailToPresentWithError:error placementId:_placementId];
}
- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [_delegate interstitialDidDismiss:interstitial placementId:_placementId];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params {
    [_delegate interstitial:interstitial didInteractWithParams:params placementId:_placementId];
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
}

- (void)interstitial:(IMInterstitial *)interstitial rewardActionCompletedWithRewards:(NSDictionary *)rewards {
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
}

@end
