//
//  ISYandexRewardedVideoAdDelegate.h
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
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


