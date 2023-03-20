//
//  ISYahooRewardedVideoDelegate.h
//  ISYahooAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YahooAds/YahooAds.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISYahooRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidLoad:(nonnull NSString *)placementId
           withRewardedVideoAd:(nonnull YASInterstitialAd *)rewardedVideoAd;
- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)placementId
                           withError:(nonnull YASErrorInfo *)errorInfo;
- (void)onRewardedVideoDidOpen:(nonnull NSString *)placementId;
- (void)onRewardedVideoShowFail:(nonnull NSString *)placementId
                      withError:(nonnull YASErrorInfo *)errorInfo;
- (void)onRewardedVideoDidClick:(nonnull NSString *)placementId;
- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)placementId;
- (void)onRewardedVideoDidClose:(nonnull NSString *)placementId;

@end

@interface ISYahooRewardedVideoDelegate : NSObject<YASInterstitialAdDelegate>

@property (nonatomic, strong) NSString *placementId;
@property (nonatomic, weak) id<ISYahooRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISYahooRewardedVideoDelegateWrapper>)delegate;

NS_ASSUME_NONNULL_END

@end

