//
//  ISChartboostBannerDelegate.h
//  ISChartboostAdapter
//
//  Created by Hadar Pur on 15/03/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <ChartboostSDK/ChartboostSDK.h>
#import <Foundation/Foundation.h>

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
