//
//  ISBidMachineInterstitialDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BidMachine/BidMachine-Swift.h>

@protocol ISInterstitialAdDelegate;
@class ISBidMachineInterstitialAdapter;

@interface ISBidMachineInterstitialDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, weak) ISBidMachineInterstitialAdapter *adapter;
@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithAdapter:(ISBidMachineInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate;

@end
