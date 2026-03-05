//
//  ISYandexInterstitialDelegate.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>

@protocol ISInterstitialAdDelegate;
@class ISYandexInterstitialAdapter;

@interface ISYandexInterstitialDelegate : NSObject <YMAInterstitialAdLoaderDelegate, YMAInterstitialAdDelegate>

@property (nonatomic, weak) ISYandexInterstitialAdapter *adapter;
@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISYandexInterstitialAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
