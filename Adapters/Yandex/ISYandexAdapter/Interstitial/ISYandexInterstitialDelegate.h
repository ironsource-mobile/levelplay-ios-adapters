//
//  ISYandexInterstitialDelegate.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YandexMobileAds;

@protocol ISInterstitialAdDelegate;

@interface ISYandexInterstitialDelegate : NSObject <YMAInterstitialAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
