//
//  ISYandexBannerDelegate.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YandexMobileAds;

@protocol ISBannerAdDelegate;

@interface ISYandexBannerDelegate : NSObject <YMABannerAdViewDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
