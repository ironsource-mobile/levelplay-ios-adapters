//
//  ISInMobiAdapter+Internal.h
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISInMobiAdapter.h"
#import "ISInMobiConstants.h"
#import <InMobiSDK/InMobiSDK.h>

@interface ISInMobiAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;
- (NSDictionary *)extras;

@end
