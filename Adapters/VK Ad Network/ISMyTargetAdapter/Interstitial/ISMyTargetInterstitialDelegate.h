//
//  ISMyTargetInterstitialDelegate.h
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MyTargetSDK/MyTargetSDK.h>

@protocol ISInterstitialAdDelegate;
@class ISMyTargetInterstitialAdapter;

@interface ISMyTargetInterstitialDelegate : NSObject <MTRGInterstitialAdDelegate>

@property (nonatomic, weak) ISMyTargetInterstitialAdapter *adapter;
@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISMyTargetInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate;

@end
