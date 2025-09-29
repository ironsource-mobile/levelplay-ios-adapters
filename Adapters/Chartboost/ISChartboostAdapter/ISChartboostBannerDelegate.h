//
//  ISChartboostBannerDelegate.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ChartboostSDK/ChartboostSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISChartboostBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull NSString *)locationId
         withCreativeId:(nonnull NSString *)creativeId;

- (void)onBannerDidFailToLoad:(nonnull NSString *)locationId
                    withError:(nonnull CHBCacheError *)error;

- (void)onBannerDidRecordImpression:(nonnull NSString *)locationId
                     withCreativeId:(nonnull NSString *)creativeId;

- (void)onBannerDidFailToShow:(nonnull NSString *)locationId
                    withError:(nonnull CHBShowError *)error;

- (void)onBannerDidClick:(nonnull NSString *)locationId
               withError:(nullable CHBClickError *)error;

- (void)onBannerDidExpire:(nonnull NSString *)locationId;

@end

@interface ISChartboostBannerDelegate : NSObject <CHBBannerDelegate>

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, weak)   id<ISChartboostBannerDelegateWrapper> delegate;

- (instancetype) initWithLocationId:(NSString *)locationId
                        andDelegate:(id<ISChartboostBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
