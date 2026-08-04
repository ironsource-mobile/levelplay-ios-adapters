//
//  ISOguryAdapter+Internal.h
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBiddingDataProtocol.h>
#import "ISOguryAdapter.h"
#import "ISOguryConstants.h"

@interface ISOguryAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
