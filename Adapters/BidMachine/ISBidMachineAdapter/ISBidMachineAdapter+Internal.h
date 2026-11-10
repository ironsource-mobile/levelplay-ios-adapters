//
//  ISBidMachineAdapter+Internal.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISBidMachineAdapter.h"
#import "ISBidMachineConstants.h"
#import <BidMachine/BidMachine-Swift.h>

@interface ISBidMachineAdapter ()

// Bidding data collection
- (void)collectBiddingDataWithAdFormat:(BidMachineAdFormat *)adFormat
                           placementId:(NSString *)placementId
                              delegate:(id<ISBiddingDataDelegate>)delegate;

@end
