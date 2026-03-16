//
//  ISVoodooAdapter+Internal.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVoodooAdapter.h"
#import "ISVoodooConstants.h"
#import <VoodooAdn/VoodooAdn.h>

@interface ISVoodooAdapter()

- (void)initSDKWithConfig:(ISAdapterConfig *)adapterConfig;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                         placementType:(AdnPlacementType)placementType
                         adapterConfig:(ISAdapterConfig *)adapterConfig;

- (InitState)getInitState;

@end

