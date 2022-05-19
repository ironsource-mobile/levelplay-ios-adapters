//
//  ISInMobiBnListener.m
//  ISInMobiAdapter
//
//  Created by Roni Schwartz on 28/11/2018.
//  Copyright © 2018 supersonic. All rights reserved.
//

#import "ISInMobiBannerListener.h"


@implementation ISInMobiBannerListener


- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISInMobiBannerListenerDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}


- (void)bannerDidFinishLoading:(IMBanner *)banner {
    [_delegate bannerDidFinishLoading:banner placementId:_placementId];
}

- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error {
    [_delegate banner:banner didFailToLoadWithError:error placementId:_placementId];
}

-(void)banner:(IMBanner *)banner didInteractWithParams:(NSDictionary *)params {
    [_delegate banner:banner didInteractWithParams:params placementId:_placementId];
}

-(void)userWillLeaveApplicationFromBanner:(IMBanner *)banner {
    [_delegate userWillLeaveApplicationFromBanner:banner placementId:_placementId];
}

-(void)bannerWillPresentScreen:(IMBanner *)banner {
    [_delegate bannerWillPresentScreenForPlacementId:_placementId];
}

-(void)bannerDidPresentScreen:(IMBanner *)banner {

}

- (void)bannerWillDismissScreen:(IMBanner *)banner {
    
}

- (void)bannerDidDismissScreen:(IMBanner *)banner {
    [_delegate bannerDidDismissScreenForPlacementId:_placementId];

}

-(void)banner:(IMBanner *)banner rewardActionCompletedWithRewards:(NSDictionary *)rewards {
}

@end
