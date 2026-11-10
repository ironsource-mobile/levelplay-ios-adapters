//
//  ISPangleRewardedDelegate.h
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISPangleRewardedDelegate : NSObject <PAGRewardedAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate>  delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
