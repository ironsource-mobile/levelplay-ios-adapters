//
//  ISAdMobInterstitialDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISAdMobInterstitialAdapter.h"

@interface ISAdMobInterstitialDelegate : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong)   NSString                            *adUnitId;
@property (nonatomic, weak)     ISAdMobInterstitialAdapter          *adapter;
@property (nonatomic, weak)     id<ISInterstitialAdapterDelegate>   delegate;
@property (nonatomic,copy)      void(^completionBlock)              (GADInterstitialAd *rewardedAd, NSError *error);

- (instancetype)initWithAdapter:(ISAdMobInterstitialAdapter *)adapter
                       adUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
