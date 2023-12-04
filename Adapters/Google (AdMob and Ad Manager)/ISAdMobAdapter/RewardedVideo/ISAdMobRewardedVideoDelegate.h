//
//  ISAdMobRewardedVideoDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISAdMobRewardedVideoAdapter.h"

@interface ISAdMobRewardedVideoDelegate : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong)   NSString                            *adUnitId;
@property (nonatomic, weak)     ISAdMobRewardedVideoAdapter         *adapter;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>  delegate;
@property (nonatomic,copy)      void(^completionBlock)              (GADRewardedAd *rewardedAd, NSError *error);

- (instancetype)initWithAdapter:(ISAdMobRewardedVideoAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
