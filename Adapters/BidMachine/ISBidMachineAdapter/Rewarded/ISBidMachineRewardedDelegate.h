//
//  ISBidMachineRewardedDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BidMachine/BidMachine-Swift.h>

@protocol ISRewardedVideoAdDelegate;
@class ISBidMachineRewardedAdapter;

@interface ISBidMachineRewardedDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) ISBidMachineRewardedAdapter *adapter;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISBidMachineRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
