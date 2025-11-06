//
//  ISLineAdapter+Internal.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISLineAdapter.h"
#import "ISLineConstants.h"


@interface ISLineAdapter()

- (void)initSDKWithAppId:(NSString *)appId;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                                 appId:(NSString *)appId
                                slotId:(NSString *)slotId;

- (InitState)getInitState;

@end
