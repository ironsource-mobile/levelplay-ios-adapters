//
//  ISAdMobRewardedVideoAdapter.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISAdMobAdapter+Internal.h"

@interface ISAdMobRewardedVideoAdapter : ISBaseRewardedVideoAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                    rewardedAd:(GADRewardedAd *)rewardedAd;
@end
