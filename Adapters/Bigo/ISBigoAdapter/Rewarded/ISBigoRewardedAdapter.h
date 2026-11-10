//
//  ISBigoRewardedAdapter.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseRewardedAdapter.h>

@class BigoRewardVideoAd;

@interface ISBigoRewardedAdapter : LevelPlayBaseRewardedAdapter

- (void)storeRewardedAd:(BigoRewardVideoAd *)ad;

@end
