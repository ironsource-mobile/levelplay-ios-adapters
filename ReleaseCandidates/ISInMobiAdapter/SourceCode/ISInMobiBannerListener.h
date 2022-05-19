//
//  ISInMobiBnListener.h
//  ISInMobiAdapter
//
//  Created by Roni Schwartz on 28/11/2018.
//  Copyright © 2018 supersonic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InMobiSDK/IMBannerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISInMobiBannerListenerDelegate  <NSObject>
- (void)bannerDidFinishLoading:(IMBanner *)banner placementId:(NSString *)placementId;
- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error  placementId:(NSString *)placementId;
- (void)banner:(IMBanner *)banner didInteractWithParams:(NSDictionary *)params  placementId:(NSString *)placementId;
- (void)userWillLeaveApplicationFromBanner:(IMBanner *)banner  placementId:(NSString *)placementId;
- (void)bannerWillPresentScreenForPlacementId:(NSString *)placementId;
- (void)bannerDidDismissScreenForPlacementId:(NSString *)placementId;
@end

@interface ISInMobiBannerListener : NSObject <IMBannerDelegate>
 @property (nonatomic, weak)id<ISInMobiBannerListenerDelegate> delegate;
 @property (nonatomic, strong)NSString* placementId;

- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISInMobiBannerListenerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
