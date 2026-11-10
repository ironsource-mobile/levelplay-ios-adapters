//
//  ISMintegralRewardedDelegate.h
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDKReward/MTGRewardAdManager.h>
#import <MTGSDKReward/MTGBidRewardAdManager.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISMintegralRewardedDelegate : NSObject <MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
