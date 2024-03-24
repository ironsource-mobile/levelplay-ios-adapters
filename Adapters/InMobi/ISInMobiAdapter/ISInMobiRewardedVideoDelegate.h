//
//  ISInMobiRewardedVideoDelegate.h
//  ISInMobiAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISInMobiRewardedVideoDelegateWrapper  <NSObject>

- (void)onRewardedVideoDidLoad:(IMInterstitial *)rewardedVideo
                   placementId:(NSString *)placementId;

- (void)onRewardedVideoDidFailToLoad:(IMInterstitial *)rewardedVideo
                               error:(IMRequestStatus *)error
                         placementId:(NSString *)placementId;

- (void)onRewardedVideoDidOpen:(IMInterstitial *)rewardedVideo
                   placementId:(NSString *)placementId;

- (void)onRewardedVideoDidFailToShow:(IMInterstitial *)rewardedVideo
                               error:(IMRequestStatus *)error
                         placementId:(NSString *)placementId;

- (void)onRewardedVideoDidClick:(IMInterstitial *)rewardedVideo
                         params:(NSDictionary *)params
                    placementId:(NSString *)placementId;

- (void)onRewardedVideoDidClose:(IMInterstitial *)rewardedVideo
                    placementId:(NSString *)placementId;

- (void)onRewardedVideoDidReceiveReward:(IMInterstitial *)rewardedVideo
                                rewards:(NSDictionary *)rewards
                            placementId:(NSString *)placementId;

@end

@interface ISInMobiRewardedVideoDelegate : NSObject <IMInterstitialDelegate>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISInMobiRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISInMobiRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
