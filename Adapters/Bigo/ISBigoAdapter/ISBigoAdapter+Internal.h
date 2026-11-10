//
//  ISBigoAdapter+Internal.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISBigoAdapter.h"
#import "ISBigoConstants.h"
#import <BigoADS/BigoAdSdk.h>

@interface ISBigoAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;
- (NSString *)getMediationInfo;

@end
