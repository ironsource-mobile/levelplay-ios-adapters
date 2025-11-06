//
//  ISPubMaticAdapter+Internal.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticAdapter.h"
#import "ISPubMaticConstants.h"
#import <OpenWrapSDK/OpenWrapSDK.h>

@interface ISPubMaticAdapter()

- (void)initSDKWithConfig:(ISAdapterConfig *)config;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                              adFormat:(POBAdFormat)adFormat
                         adapterConfig:(ISAdapterConfig *)adapterConfig;

- (InitState)getInitState;

@end
