//
//  ISChartboostRewardedVideoDelegate.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ChartboostSDK/ChartboostSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISChartboostRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidLoad:(nonnull NSString *)locationId
                withCreativeId:(nonnull NSString *)creativeId;

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)locationId
                           withError:(nonnull CHBCacheError *)error;

- (void)onRewardedVideoShowFail:(nonnull NSString *)locationId
                      withError:(nonnull CHBShowError *)error;

- (void)onRewardedVideoDidClick:(nonnull NSString *)locationId
                      withError:(nullable CHBClickError *)error;

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)locationId;

- (void)onRewardedVideoDidEnd:(nonnull NSString *)locationId;

- (void)onRewardedVideoDidClose:(nonnull NSString *)locationId;

- (void)onRewardedVideoDidExpire:(nonnull NSString *)locationId;

- (void)onRewardedVideoDidRecordImpression:(nonnull NSString *)locationId
                            withCreativeId:(nonnull NSString *)creativeId;

@end

@interface ISChartboostRewardedVideoDelegate : NSObject <CHBRewardedDelegate>

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, weak)   id<ISChartboostRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithLocationId:(NSString *)locationId
                       andDelegate:(id<ISChartboostRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
