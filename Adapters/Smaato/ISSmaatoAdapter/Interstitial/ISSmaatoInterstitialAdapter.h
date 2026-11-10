//
//  ISSmaatoInterstitialAdapter.h
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseInterstitialAdapter.h>
#import <SmaatoSDKInterstitial/SmaatoSDKInterstitial.h>

@interface ISSmaatoInterstitialAdapter : LevelPlayBaseInterstitialAdapter

- (void)setInterstitialAd:(SMAInterstitial *)ad;

@end
