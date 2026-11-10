//
//  ISVungleAdapter+Internal.h
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBiddingDataProtocol.h>
#import "ISVungleAdapter.h"
#import "ISVungleConstants.h"

@interface ISVungleAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
