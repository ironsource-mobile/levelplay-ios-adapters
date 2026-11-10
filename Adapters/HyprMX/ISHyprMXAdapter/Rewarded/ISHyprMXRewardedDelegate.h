//
//  ISHyprMXRewardedDelegate.h
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <HyprMX/HyprMX.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISHyprMXRewardedDelegate : NSObject <HyprMXPlacementShowDelegate, HyprMXPlacementExpiredDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
