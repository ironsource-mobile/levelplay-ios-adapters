//
//  ISYandexInterstitialAdapter.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISYandexAdapter+Internal.h"

@interface ISYandexInterstitialAdapter : ISBaseInterstitialAdapter

- (instancetype)initWithYandexAdapter:(ISYandexAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                interstitialAd:(YMAInterstitialAd *)interstitialAd;

@end
