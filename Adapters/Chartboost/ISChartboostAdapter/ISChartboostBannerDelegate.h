//
//  ISChartboostBannerDelegate.h
//  ISChartboostAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ChartboostSDK/ChartboostSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISChartboostBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull NSString *)locationId;

- (void)onBannerDidFailToLoad:(nonnull NSString *)locationId
                    withError:(nonnull CHBCacheError *)error;

- (void)onBannerDidShow:(nonnull NSString *)locationId;

- (void)onBannerDidFailToShow:(nonnull NSString *)locationId
                    withError:(nonnull CHBShowError *)error;

- (void)onBannerDidClick:(nonnull NSString *)locationId
               withError:(nullable CHBClickError *)error;


@end

@interface ISChartboostBannerDelegate : NSObject <CHBBannerDelegate>

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, weak)   id<ISChartboostBannerDelegateWrapper> delegate;

- (instancetype) initWithLocationId:(NSString *)locationId
                        andDelegate:(id<ISChartboostBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
