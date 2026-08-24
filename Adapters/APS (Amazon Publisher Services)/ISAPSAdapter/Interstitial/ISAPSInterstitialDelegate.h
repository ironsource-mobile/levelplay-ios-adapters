//
//  ISAPSInterstitialDelegate.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@protocol ISInterstitialAdDelegate;

@interface ISAPSInterstitialDelegate : NSObject <DTBAdInterstitialDispatcherDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
