//
//  ISMyTargetRewardedVideoListener.h
//  ISMyTargetAdapter
//
//  Created by Hadar Pur on 14/07/2020.
//

#import <Foundation/Foundation.h>
#import <MyTargetSDK/MyTargetSDK.h>

@protocol ISMyTargetRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoLoadSuccess:(MTRGRewardedAd *)rewardedVideoAd;
- (void)onRewardedVideoLoadFailWithReason:(NSString *)reason rewardedVideoAd:(MTRGRewardedAd *)rewardedVideoAd;
- (void)onRewardedVideoClicked:(MTRGRewardedAd *)rewardedVideoAd;
- (void)onRewardedVideoDisplay:(MTRGRewardedAd *)rewardedVideoAd;
- (void)onRewardedVideoClosed:(MTRGRewardedAd *)rewardedVideoAd;
- (void)onRewardedVideoCompleted:(MTRGRewardedAd *)rewardedVideoAd;

@end

@interface ISMyTargetRewardedVideoListener : NSObject <MTRGRewardedAdDelegate>

@property (nonatomic, weak) id<ISMyTargetRewardedVideoDelegateWrapper> delegate;


- (instancetype)initWithDelegate:(id<ISMyTargetRewardedVideoDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end
