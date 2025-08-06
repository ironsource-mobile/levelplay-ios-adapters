//
//  ISAdMobInterstitialAdapter.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISAdMobAdapter+Internal.h"

@interface ISAdMobInterstitialAdapter : ISBaseInterstitialAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                interstitialAd:(GADInterstitialAd *)interstitialAd;

@end

