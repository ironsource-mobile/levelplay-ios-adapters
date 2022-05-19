//
//  ISChartboostRewardedListener.h
//  ISChartboostAdapter
//
//  Created by Hadar Pur on 12/03/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Chartboost.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISChartboostRewardedWrapper <NSObject>

- (void) didDisplayRewardedVideo:(NSString *)location;
- (void) didCacheRewardedVideo:(NSString *)location;
- (void) didFailToShowRewardedVideo:(NSString *)location
                          withError:(CHBShowError *)error;
- (void) didFailToCacheRewardedVideo:(NSString *)location
                           withError:(CHBCacheError *)error;
- (void) didCompleteRewardedVideo:(NSString *)location;
- (void) didClickRewardedVideo:(NSString *)location;
- (void) didDismissRewardedVideo:(NSString *)location;

@end

@interface ISChartboostRewardedListener : NSObject <CHBRewardedDelegate>

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, weak)   id<ISChartboostRewardedWrapper> delegate;

- (instancetype) initWithPlacementId:(NSString *)locationId
                         andDelegate:(id<ISChartboostRewardedWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
