//
//  ISBidMachineBannerDelegate.h
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <BidMachine/BidMachine.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <ISBidMachineAdapter.h>

@interface ISBidMachineBannerDelegate : NSObject <BidMachineAdDelegate>

@property (nonatomic, strong) BidMachineBanner *banner;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithBanner:(BidMachineBanner *)banner
                   andDelegate:(id<ISBannerAdapterDelegate>)delegate;

@end
