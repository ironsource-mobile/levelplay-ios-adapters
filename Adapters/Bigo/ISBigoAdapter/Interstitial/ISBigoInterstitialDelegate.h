//
//  ISBigoInterstitialDelegate.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BigoADS/BigoInterstitialAdLoader.h>

@protocol ISInterstitialAdDelegate;
@class ISBigoInterstitialAdapter;
@class BigoInterstitialAd;

@interface ISBigoInterstitialDelegate : NSObject <BigoInterstitialAdLoaderDelegate, BigoAdInteractionDelegate>

@property (nonatomic, weak) ISBigoInterstitialAdapter     *adapter;
@property (nonatomic, weak) id<ISInterstitialAdDelegate>  delegate;

- (instancetype)initWithAdapter:(ISBigoInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate;

@end
