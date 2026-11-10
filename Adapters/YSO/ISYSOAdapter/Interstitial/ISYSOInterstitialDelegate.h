//
//  ISYSOInterstitialDelegate.h
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YsoNetwork/YsoNetwork.h>
#import <YsoNetwork/YsoNetwork-Swift.h>

@protocol ISInterstitialAdDelegate;

@interface ISYSOInterstitialDelegate : NSObject

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

- (void)handleOnLoad:(e_ActionError)error;
- (void)handleOnDisplay:(YNWebView *)view;
- (void)handleOnClick;
- (void)handleOnClose:(BOOL)display complete:(BOOL)complete;

@end
