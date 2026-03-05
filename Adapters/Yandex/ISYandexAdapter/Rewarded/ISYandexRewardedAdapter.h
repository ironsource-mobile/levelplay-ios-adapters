//
//  ISYandexRewardedAdapter.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseRewardedAdapter.h>

@class YMARewardedAd;

@interface ISYandexRewardedAdapter : LevelPlayBaseRewardedAdapter

- (void)setAdAvailability:(BOOL)availability
           withRewardedAd:(YMARewardedAd *)rewardedAd;

@end
