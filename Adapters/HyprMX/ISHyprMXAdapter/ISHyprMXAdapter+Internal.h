//
//  ISHyprMXAdapter+Internal.h
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBiddingDataProtocol.h>
#import "ISHyprMXAdapter.h"
#import "ISHyprMXConstants.h"

@interface ISHyprMXAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
