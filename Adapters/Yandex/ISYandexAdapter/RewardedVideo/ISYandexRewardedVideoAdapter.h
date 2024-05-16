//
//  ISYandexRewardedVideoAdapter.h
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISYandexAdapter+Internal.h"

@interface ISYandexRewardedVideoAdapter : ISBaseRewardedVideoAdapter

- (instancetype)initWithYandexAdapter:(ISYandexAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                               rewardedVideoAd:(YMARewardedAd *)rewardedVideoAd;

@end
