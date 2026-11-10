//
//  ISBigoInterstitialAdapter.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseInterstitialAdapter.h>

@class BigoInterstitialAd;

@interface ISBigoInterstitialAdapter : LevelPlayBaseInterstitialAdapter

- (void)storeInterstitialAd:(BigoInterstitialAd *)ad;

@end
