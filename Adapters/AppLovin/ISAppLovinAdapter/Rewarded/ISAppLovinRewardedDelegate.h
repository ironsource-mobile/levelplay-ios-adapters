//
//  ISAppLovinRewardedDelegate.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>

@protocol ISRewardedVideoAdDelegate;
@class ISAppLovinRewardedAdapter;

@interface ISAppLovinRewardedDelegate : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdRewardDelegate, ALAdVideoPlaybackDelegate>

@property (nonatomic, weak) ISAppLovinRewardedAdapter *adapter;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISAppLovinRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
