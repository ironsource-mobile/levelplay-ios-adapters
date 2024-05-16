//
//  ISYandexInterstitialAdapter.h
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISYandexAdapter+Internal.h"

@interface ISYandexInterstitialAdapter : ISBaseInterstitialAdapter

- (instancetype)initWithYandexAdapter:(ISYandexAdapter *)adapter;

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                interstitialAd:(YMAInterstitialAd *)interstitialAd;

@end
