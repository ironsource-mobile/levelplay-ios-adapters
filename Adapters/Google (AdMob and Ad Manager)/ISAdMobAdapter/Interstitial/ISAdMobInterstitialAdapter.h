//
//  ISAdMobInterstitialAdapter.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISAdMobAdapter+Internal.h"

@interface ISAdMobInterstitialAdapter : ISBaseInterstitialAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                interstitialAd:(GADInterstitialAd *)interstitialAd;

@end

