//
//  ISSmaatoRewardedDelegate.h
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SmaatoSDKRewardedAds/SmaatoSDKRewardedAds.h>

@protocol ISRewardedVideoAdDelegate;
@class ISSmaatoRewardedAdapter;

@interface ISSmaatoRewardedDelegate : NSObject <SMARewardedInterstitialDelegate>

@property (nonatomic, weak) ISSmaatoRewardedAdapter *adapter;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISSmaatoRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
