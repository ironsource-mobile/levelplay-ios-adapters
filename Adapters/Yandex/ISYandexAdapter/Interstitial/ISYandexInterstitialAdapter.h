//
//  ISYandexInterstitialAdapter.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseInterstitialAdapter.h>

@class YMAInterstitialAd;

@interface ISYandexInterstitialAdapter : LevelPlayBaseInterstitialAdapter

- (void)setAdAvailability:(BOOL)availability
        withInterstitialAd:(YMAInterstitialAd *)interstitialAd;

@end
