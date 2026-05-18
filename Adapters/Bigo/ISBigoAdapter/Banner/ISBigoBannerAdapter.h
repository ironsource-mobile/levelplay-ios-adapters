//
//  ISBigoBannerAdapter.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseBannerAdapter.h>

@class BigoBannerAd;

@interface ISBigoBannerAdapter : LevelPlayBaseBannerAdapter

- (void)storeBannerAd:(BigoBannerAd *)ad;

@end
