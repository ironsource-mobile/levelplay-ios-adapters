//
//  ISYandexRewardedVideoAdapter.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISYandexAdapter+Internal.h"

@interface ISYandexRewardedVideoAdapter : ISBaseRewardedVideoAdapter

- (instancetype)initWithYandexAdapter:(ISYandexAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                               rewardedVideoAd:(YMARewardedAd *)rewardedVideoAd;

@end
