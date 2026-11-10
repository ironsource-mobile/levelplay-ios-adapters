//
//  ISMolocoAdapter+Internal.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISMolocoAdapter.h"
#import "ISMolocoConstants.h"
#import <MolocoSDK/MolocoSDK-Swift.h>

@interface ISMolocoAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
