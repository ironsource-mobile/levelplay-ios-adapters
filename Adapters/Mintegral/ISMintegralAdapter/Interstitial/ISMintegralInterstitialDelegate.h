//
//  ISMintegralInterstitialDelegate.h
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDKNewInterstitial/MTGNewInterstitialBidAdManager.h>

@protocol ISInterstitialAdDelegate;

@interface ISMintegralInterstitialDelegate : NSObject <MTGNewInterstitialBidAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
