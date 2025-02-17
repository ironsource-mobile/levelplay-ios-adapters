//
//  ISBidMachineInterstitialDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <ISBidMachineAdapter.h>

@interface ISBidMachineInterstitialDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
