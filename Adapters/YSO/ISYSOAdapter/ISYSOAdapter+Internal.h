//
//  ISYSOAdapter+Internal.h
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYSOAdapter.h"
#import "ISYSOConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBiddingDataProtocol.h>
#import <YsoNetwork/YsoNetwork.h>
#import <YsoNetwork/YsoNetwork-Swift.h>

@interface ISYSOAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

+ (NSString *)loadErrorToString:(e_ActionError)error;

@end
