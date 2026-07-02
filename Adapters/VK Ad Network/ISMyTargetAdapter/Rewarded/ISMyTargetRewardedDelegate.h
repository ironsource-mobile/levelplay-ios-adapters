//
//  ISMyTargetRewardedDelegate.h
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MyTargetSDK/MyTargetSDK.h>

@protocol ISRewardedVideoAdDelegate;
@class ISMyTargetRewardedAdapter;

@interface ISMyTargetRewardedDelegate : NSObject <MTRGRewardedAdDelegate>

@property (nonatomic, weak) ISMyTargetRewardedAdapter *adapter;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISMyTargetRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
