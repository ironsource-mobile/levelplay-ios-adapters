//
//  ISPangleInterstitialDelegate.h
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>

@protocol ISInterstitialAdDelegate;

@interface ISPangleInterstitialDelegate : NSObject <PAGLInterstitialAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate>   delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
