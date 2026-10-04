//
//  ISFacebookAdapter+Internal.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISFacebookAdapter.h"
#import "ISFacebookConstants.h"
#import <IronSource/ISBiddingDataProtocol.h>

@interface ISFacebookAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
