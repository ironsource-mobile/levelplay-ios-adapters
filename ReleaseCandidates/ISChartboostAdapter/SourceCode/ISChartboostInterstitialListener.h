//
//  ISChartboostInterstitialListener.h
//  ISChartboostAdapter
//
//  Created by Hadar Pur on 12/03/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Chartboost.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISChartboostInterstitialWrapper <NSObject>

- (void) didDisplayInterstitial:(NSString *)location;
- (void) didCacheInterstitial:(NSString *)location;
- (void) didFailToCacheInterstitial:(NSString *)location
                          withError:(CHBCacheError *)error;
- (void) didFailToShowInterstitial:(NSString *)location
                         withError:(CHBShowError *)error;
- (void) didDismissInterstitial:(NSString *)location;
- (void) didClickInterstitial:(NSString *)location;

@end

@interface ISChartboostInterstitialListener : NSObject <CHBInterstitialDelegate>

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, weak)   id<ISChartboostInterstitialWrapper> delegate;

- (instancetype) initWithPlacementId:(NSString *)locationId
                         andDelegate:(id<ISChartboostInterstitialWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
