//
//  ISAppLovinInterstitialAdapter.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <IronSource/LevelPlayBaseInterstitialAdapter.h>

@interface ISAppLovinInterstitialAdapter : LevelPlayBaseInterstitialAdapter

- (void)setLoadedAd:(ALAd *)ad;

@end
