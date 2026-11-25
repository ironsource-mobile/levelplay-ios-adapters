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

// BidMachine instance, nil until the SDK is initialized
+ (BidMachineInstance *)bidMachineInstance;

// Bidding data collection
- (void)collectBiddingDataWithPlacementId:(NSString *)placementId
                                 delegate:(id<ISBiddingDataDelegate>)delegate;

@end
