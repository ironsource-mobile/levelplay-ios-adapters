//
//  ISBidMachineInterstitialDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BidMachine/BidMachine-Swift.h>

@protocol ISInterstitialAdDelegate;

@interface ISBidMachineInterstitialDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
