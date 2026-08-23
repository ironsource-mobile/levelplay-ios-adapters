//
//  ISAppLovinInterstitialDelegate.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>

@protocol ISInterstitialAdDelegate;
@class ISAppLovinInterstitialAdapter;

@interface ISAppLovinInterstitialDelegate : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate>

@property (nonatomic, weak) ISAppLovinInterstitialAdapter *adapter;
@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISAppLovinInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate;

@end
