//
//  ISBidMachineBannerDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <ISBidMachineAdapter.h>

@interface ISBidMachineBannerDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, strong) BidMachineBanner *banner;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithBanner:(BidMachineBanner *)banner
                   andDelegate:(id<ISBannerAdapterDelegate>)delegate;

@end
