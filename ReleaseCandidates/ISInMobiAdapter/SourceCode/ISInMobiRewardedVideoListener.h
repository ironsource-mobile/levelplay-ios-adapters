//
//  ISInMobiRvListener.h
//  ISInMobiAdapter
//
//  Created by Roni Schwartz on 27/11/2018.
//  Copyright © 2018 supersonic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InMobiSDK/IMInterstitialDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISInMobiRewardedVideoListenerDelegate  <NSObject>
- (void)rewardedVideoDidFinishLoading:(IMInterstitial *)interstitial placementId:(NSString *)placementId;
- (void)rewardedVideo:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error placementId:(NSString *)placementId;
- (void)rewardedVideoDidPresent:(IMInterstitial *)interstitial placementId:(NSString *)placementId;
- (void)rewardedVideo:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error placementId:(NSString *)placementId;
- (void)rewardedVideoDidDismiss:(IMInterstitial *)interstitial placementId:(NSString *)placementId;
- (void)rewardedVideo:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params placementId:(NSString *)placementId;
- (void)rewardedVideo:(IMInterstitial *)interstitial rewardActionCompletedWithRewards:(NSDictionary *)rewards placementId:(NSString *)placementId;
@end

@interface ISInMobiRewardedVideoListener : NSObject <IMInterstitialDelegate>

@property (nonatomic, weak)   id<ISInMobiRewardedVideoListenerDelegate> delegate;
@property (nonatomic, strong) NSString* placementId;


- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISInMobiRewardedVideoListenerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
