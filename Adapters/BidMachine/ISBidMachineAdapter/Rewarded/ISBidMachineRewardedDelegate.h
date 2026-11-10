//
//  ISBidMachineRewardedDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BidMachine/BidMachine-Swift.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISBidMachineRewardedDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
