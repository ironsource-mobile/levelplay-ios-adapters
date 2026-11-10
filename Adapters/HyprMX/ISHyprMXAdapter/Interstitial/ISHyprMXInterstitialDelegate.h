//
//  ISHyprMXInterstitialDelegate.h
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <HyprMX/HyprMX.h>

@protocol ISInterstitialAdDelegate;

@interface ISHyprMXInterstitialDelegate : NSObject <HyprMXPlacementShowDelegate, HyprMXPlacementExpiredDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
