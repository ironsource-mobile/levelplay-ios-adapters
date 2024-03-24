//
//  ISInMobiBannerDelegate.h
//  ISInMobiAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISInMobiBannerDelegateWrapper  <NSObject>

- (void)onBannerDidLoad:(IMBanner *)banner
            placementId:(NSString *)placementId;

- (void)onBannerDidFailToLoad:(IMBanner *)banner
                        error:(IMRequestStatus *)error
                  placementId:(NSString *)placementId;

- (void)onBannerDidShow:(IMBanner *)banner
            placementId:(NSString *)placementId;

- (void)onBannerDidClick:(IMBanner *)banner
                  params:(NSDictionary *)params
             placementId:(NSString *)placementId;

- (void)onBannerWillLeaveApplication:(IMBanner *)banner
                         placementId:(NSString *)placementId;

- (void)onBannerWillPresentScreenWithPlacementId:(NSString *)placementId;

- (void)onBannerDidDismissScreenWithPlacementId:(NSString *)placementId;

@end

@interface ISInMobiBannerDelegate : NSObject <IMBannerDelegate>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISInMobiBannerDelegateWrapper> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISInMobiBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
