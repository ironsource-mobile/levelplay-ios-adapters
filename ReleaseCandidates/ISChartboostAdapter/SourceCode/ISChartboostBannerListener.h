//
//  ISChartboostBannerListener.h
//  ISChartboostAdapter
//
//  Created by Hadar Pur on 15/03/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Chartboost.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISChartboostBannerWrapper <NSObject>

- (void) didShowBanner:(NSString *)location;
- (void) didCacheBanner:(NSString *)location;
- (void) didFailToShowBanner:(NSString *)location
                   withError:(CHBShowError *)error;
- (void) didFailToCacheBanner:(NSString *)location
                    withError:(CHBCacheError *)error;
- (void) didClickBanner:(NSString *)location;

@end

@interface ISChartboostBannerListener : NSObject <CHBBannerDelegate>

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, weak)   id<ISChartboostBannerWrapper> delegate;

- (instancetype) initWithPlacementId:(NSString *)locationId
                         andDelegate:(id<ISChartboostBannerWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
