//
//  ISVungleRewardedDelegate.h
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISVungleRewardedDelegate : NSObject <VungleRewardedDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
