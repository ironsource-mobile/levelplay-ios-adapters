//
//  ISBidMachineBannerDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BidMachine/BidMachine-Swift.h>

@protocol ISBannerAdDelegate;
@class BidMachineBanner;

@interface ISBidMachineBannerDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, strong) BidMachineBanner         *banner;
@property (nonatomic, weak) id<ISBannerAdDelegate>     delegate;

- (instancetype)initWithBanner:(BidMachineBanner *)banner
                      delegate:(id<ISBannerAdDelegate>)delegate;

@end
