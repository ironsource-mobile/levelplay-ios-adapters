//
//  ISYandexInterstitialAdDelegate.h
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>

@interface ISYandexInterstitialAdDelegate : NSObject <YMAInterstitialAdLoaderDelegate, YMAInterstitialAdDelegate>

@property (nonatomic, weak) ISYandexInterstitialAdapter *adapter;
@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> delegate;

- (instancetype)initWithAdapter:(ISYandexInterstitialAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;


@end

