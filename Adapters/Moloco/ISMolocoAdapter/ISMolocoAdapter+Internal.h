//
//  ISMolocoBannerAdapter.h
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISMolocoAdapter.h"
#import "ISMolocoConstants.h"
#import <MolocoSDK/MolocoSDK-Swift.h>

@interface ISMolocoAdapter()

- (void)initSDKWithAppKey:(NSString *)appKey;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

@end
