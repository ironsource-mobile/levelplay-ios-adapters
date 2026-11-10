//
//  ISFacebookRewardedDelegate.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISFacebookRewardedDelegate : NSObject <FBRewardedVideoAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
