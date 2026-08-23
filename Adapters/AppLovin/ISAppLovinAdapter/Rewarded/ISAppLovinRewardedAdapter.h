//
//  ISAppLovinRewardedAdapter.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <IronSource/LevelPlayBaseRewardedAdapter.h>

@interface ISAppLovinRewardedAdapter : LevelPlayBaseRewardedAdapter

- (void)setLoadedAd:(ALAd *)ad;

@end
