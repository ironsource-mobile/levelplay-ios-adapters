//
//  ISMolocoBannerAdapter.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISMolocoAdapter.h"
#import "ISMolocoConstants.h"
#import <MolocoSDK/MolocoSDK-Swift.h>

@interface ISMolocoAdapter()

- (void)initSDKWithAppKey:(NSString *)appKey;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

- (MolocoCreateAdParams *)createMolocoAdParamsWithAdUnitId:(NSString *)adUnitId;

@end
