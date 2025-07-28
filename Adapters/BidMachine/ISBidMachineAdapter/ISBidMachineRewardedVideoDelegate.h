//
//  ISBidMachineRewardedVideoDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <ISBidMachineAdapter.h>

@interface ISBidMachineRewardedVideoDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
