//
//  ISSmaatoInterstitialDelegate.h
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SmaatoSDKInterstitial/SmaatoSDKInterstitial.h>

@protocol ISInterstitialAdDelegate;
@class ISSmaatoInterstitialAdapter;

@interface ISSmaatoInterstitialDelegate : NSObject <SMAInterstitialDelegate>

@property (nonatomic, weak) ISSmaatoInterstitialAdapter *adapter;
@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISSmaatoInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate;

@end
