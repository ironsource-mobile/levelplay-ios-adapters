//
//  ISInMobiBannerDelegate.m
//  ISInMobiAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISInMobiBannerDelegate.h>

@implementation ISInMobiBannerDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISInMobiBannerDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark IMBannerDelegate

/**
 Called when the banner is loaded and ready to be placed in the view hierarchy.
 @param banner View that was loaded
 */
- (void)bannerDidFinishLoading:(IMBanner *)banner {
    [self.delegate onBannerDidLoad:banner
                       placementId:self.placementId];
}

/**
 Called when `InMobiBanner` has failed to load with some error.
 @param banner View that encountered an error.
 @param error error that occurred
 */
- (void)banner:(IMBanner *)banner
didFailToLoadWithError:(IMRequestStatus *)error {
    [self.delegate onBannerDidFailToLoad:banner
                                   error:error
                             placementId:self.placementId];
}

/**
 Called when `InMobiBanner` banner ad impression has been tracked.
 @param banner View that tracked impression.
 */
- (void)bannerAdImpressed:(IMBanner*)banner {
     [self.delegate onBannerDidShow:banner
                        placementId:self.placementId];
}

/**
 Called when the user clicks the banner.
 @param banner View that the click occurred on.
 @param params additional data regarding the click.
 */
- (void)banner:(IMBanner *)banner
didInteractWithParams:(NSDictionary *)params {
    [self.delegate onBannerDidClick:banner
                             params:params
                        placementId:self.placementId];
}

/**
 Called when the user is going to be redirect outside of the application.
 @param banner View that caused the user to leave the application.
 */
- (void)userWillLeaveApplicationFromBanner:(IMBanner *)banner {
    [self.delegate onBannerWillLeaveApplication:banner
                                    placementId:self.placementId];
}

/**
 Called when the full screen view will be presented
 @param banner View that will be presented.
 */
- (void)bannerWillPresentScreen:(IMBanner *)banner {
    [self.delegate onBannerWillPresentScreenWithPlacementId:self.placementId];
}

/**
 Called when the full screen view did dismiss.
 @param banner View that stopped displaying.
 */
- (void)bannerDidDismissScreen:(IMBanner *)banner {
    [self.delegate onBannerDidDismissScreenWithPlacementId:self.placementId];
}

@end
