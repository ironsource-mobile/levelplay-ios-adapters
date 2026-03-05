//
//  ISYandexRewardedDelegate.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>

@protocol ISRewardedVideoAdDelegate;
@class ISYandexRewardedAdapter;

@interface ISYandexRewardedDelegate : NSObject <YMARewardedAdLoaderDelegate, YMARewardedAdDelegate>

@property (nonatomic, weak) ISYandexRewardedAdapter *adapter;
@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISYandexRewardedAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
