//
//  ISAdMobRewardedVideoDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISAdMobRewardedVideoAdapter.h"

@interface ISAdMobRewardedVideoDelegate : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong)   NSString                            *adUnitId;
@property (nonatomic, weak)     ISAdMobRewardedVideoAdapter         *adapter;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>  delegate;

- (instancetype)initWithAdapter:(ISAdMobRewardedVideoAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
