//
//  ISPangleAdapter+Internal.h
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPangleAdapter.h"
#import "ISPangleConstants.h"
#import <PAGAdSDK/PAGAdSDK.h>

@interface ISPangleAdapter ()

- (void)collectBiddingDataWithSlotId:(NSString *)slotId
                            delegate:(id<ISBiddingDataDelegate>)delegate;
- (BOOL)isCoppaChildUser;
- (NSError *)childError;

@end
