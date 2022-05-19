//
//  ISLiftoffRewardedVideoListener.m
//  ISLiftoffAdapter
//
//  Created by Roi Eshel on 14/09/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LiftoffAds/LiftoffAds.h>

@protocol ISLiftoffRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoLoadSuccess:(LOInterstitial *)rewardedVideoAd;
- (void)onRewardedVideoLoadFail:(LOInterstitial *)rewardedVideoAd;
- (void)onRewardedVideoShowFail:(LOInterstitial *)rewardedVideoAd;
- (void)onRewardedVideoDidOpen:(LOInterstitial *)rewardedVideoAd;
- (void)onRewardedVideoDidShow:(LOInterstitial *)rewardedVideoAd;
- (void)onRewardedVideoDidClick:(LOInterstitial *)rewardedVideoAd;
- (void)onRewardedVideoDidReceiveReward:(LOInterstitial *)rewardedVideoAd;
- (void)onRewardedVideoDidClose:(LOInterstitial *)rewardedVideoAd;

@end

@interface ISLiftoffRewardedVideoListener : NSObject <LOInterstitialDelegate>

@property (nonatomic, weak) id<ISLiftoffRewardedVideoDelegateWrapper> delegate;


- (instancetype)initWithDelegate:(id<ISLiftoffRewardedVideoDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end
