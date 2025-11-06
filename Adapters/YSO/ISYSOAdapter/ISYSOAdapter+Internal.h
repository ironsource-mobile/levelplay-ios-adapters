//
//  ISYSOAdapter+Internal.h
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYSOAdapter.h"
#import "ISYSOConstants.h"
#import <YsoNetwork/YsoNetwork.h>
#import <YsoNetwork/YsoNetwork-Swift.h>

@interface ISYSOAdapter()

- (void)initSDKWithPlacementKey:(NSString *)placementKey;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

- (NSString *)ysoLoadErrorToString:(e_ActionError)error;

@end
