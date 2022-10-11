//
//  ISVungleRewardedVideoAdapterRouter.h
//  ISVungleAdapter
//
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import "IronSource/ISBaseAdapter+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@class ISVungleAdapter;
@interface ISVungleRewardedVideoAdapterRouter : NSObject<VungleRewardedDelegate>

@property (nonatomic, strong) NSString* placementID;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> delegate;
@property (nonatomic, strong) VungleRewarded *rewardedVideoAd;
@property (nonatomic, assign) BOOL isNeededInitCallback;

- (instancetype)initWithPlacementID:(NSString *)placementID
                           delegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

- (void)loadRewardedVideoAd;
- (void)playRewardedVideoAdWithViewController:(UIViewController *)viewController;
- (void)setBidPayload:(NSString * _Nullable)bidPayload;

- (void)rewardedVideoInitSuccess;
- (void)rewardedVideoInitFailed:(NSError *)error;
- (void)rewardedVideoHasChangedAvailability:(BOOL)available;

@end

NS_ASSUME_NONNULL_END
