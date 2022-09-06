//
//  ISVungleRewardedVideoAdapterRouter.h
//  ISVungleAdapter
//
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAds/VungleAds.h>
#import "IronSource/ISBaseAdapter+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@class ISVungleAdapter;
@interface ISVungleRewardedVideoAdapterRouter : NSObject<VungleRewardedDelegate>

@property (nonatomic, strong) NSString* placementID;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> delegate;
@property (nonatomic, weak) ISVungleAdapter *parentAdapter;
@property (nonatomic, strong) VungleRewarded *rewardedVideoAd;

- (instancetype)initWithPlacementID:(NSString *)placementID
                      parentAdapter:(ISVungleAdapter *)parentAdapter
                           delegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

- (void)loadRewardedVideoAd;
- (void)playRewardedVideoAdWithViewController:(UIViewController *)viewController;
- (void)setBidPayload:(NSString * _Nullable)bidPayload;

- (void)rewardedVideoInitSuccess;
- (void)rewardedVideoInitFailed:(NSError *)error;
- (void)rewardedVideoHasChangedAvailability:(BOOL)available;

@end

NS_ASSUME_NONNULL_END
