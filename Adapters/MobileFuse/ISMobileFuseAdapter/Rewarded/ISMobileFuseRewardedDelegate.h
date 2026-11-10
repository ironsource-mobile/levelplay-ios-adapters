//
//  ISMobileFuseRewardedDelegate.h
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileFuseSDK/MobileFuse.h>
#import <MobileFuseSDK/MFRewardedAd.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISMobileFuseRewardedDelegate : NSObject <IMFAdCallbackReceiver>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
