//
//  ISAdMobRewardedVideoAdapter.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISAdMobAdapter+Internal.h"

@interface ISAdMobRewardedVideoAdapter : ISBaseRewardedVideoAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                    rewardedAd:(GADRewardedAd *)rewardedAd;

- (GADSignalRequest *)createSignalRequestWithAdData:(NSDictionary *)adData
                                      adapterConfig:(ISAdapterConfig *)adapterConfig;

@end
