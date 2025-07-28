//
//  ISBidMachineInterstitialDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <ISBidMachineAdapter.h>

@interface ISBidMachineInterstitialDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
