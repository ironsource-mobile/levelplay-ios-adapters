//
//  ISMyTargetAdapter+Internal.h
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBiddingDataProtocol.h>
#import "ISMyTargetAdapter.h"
#import "ISMyTargetConstants.h"

@interface ISMyTargetAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
