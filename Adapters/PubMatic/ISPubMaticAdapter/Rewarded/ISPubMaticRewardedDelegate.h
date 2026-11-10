//
//  ISPubMaticRewardedDelegate.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenWrapSDK/OpenWrapSDK.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISPubMaticRewardedDelegate : NSObject <POBRewardedAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
