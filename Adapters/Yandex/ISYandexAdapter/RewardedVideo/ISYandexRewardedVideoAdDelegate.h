//
//  ISYandexRewardedVideoAdDelegate.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>

@interface ISYandexRewardedVideoAdDelegate : NSObject <YMARewardedAdLoaderDelegate, YMARewardedAdDelegate>

@property (nonatomic, weak) ISYandexRewardedVideoAdapter *adapter;
@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> delegate;

- (instancetype)initWithAdapter:(ISYandexRewardedVideoAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end


