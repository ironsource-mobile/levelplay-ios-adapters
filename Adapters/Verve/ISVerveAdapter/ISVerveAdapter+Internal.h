//
//  ISVerveAdapter+Internal.h
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVerveAdapter.h"
#import "ISVerveConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <HyBid/HyBid.h>
#if __has_include(<HyBid/HyBid-Swift.h>)
    #import <HyBid/HyBid-Swift.h>
#else
    #import "HyBid-Swift.h"
#endif

@interface ISVerveAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
