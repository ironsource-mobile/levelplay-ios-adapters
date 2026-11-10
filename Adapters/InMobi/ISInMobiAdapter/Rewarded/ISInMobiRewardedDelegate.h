//
//  ISInMobiRewardedDelegate.h
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISInMobiRewardedDelegate : NSObject <IMInterstitialDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
