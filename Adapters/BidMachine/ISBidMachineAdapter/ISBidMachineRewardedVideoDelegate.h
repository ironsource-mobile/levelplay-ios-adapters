//
//  ISBidMachineRewardedVideoDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <ISBidMachineAdapter.h>

@interface ISBidMachineRewardedVideoDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
