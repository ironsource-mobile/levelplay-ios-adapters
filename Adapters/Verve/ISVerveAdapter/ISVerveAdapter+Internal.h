//
//  ISVerveAdapter+Internal.h
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISVerveAdapter.h"
#import "ISVerveConstants.h"
#import <HyBid/HyBid.h>
#if __has_include(<HyBid/HyBid-Swift.h>)
    #import <HyBid/HyBid-Swift.h>
#else
    #import "HyBid-Swift.h"
#endif

@interface ISVerveAdapter()

- (void)initSDKWithAppToken:(NSString *)appToken;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

@end
