//
//  ISFyberAdapter+Internal.h
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBiddingDataProtocol.h>
#import "ISFyberAdapter.h"
#import "ISFyberConstants.h"

@interface ISFyberAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
