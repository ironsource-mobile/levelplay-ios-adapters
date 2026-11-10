//
//  ISPubMaticAdapter+Internal.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticAdapter.h"
#import "ISPubMaticConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBiddingDataProtocol.h>
#import <OpenWrapSDK/OpenWrapSDK.h>

@interface ISPubMaticAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                              adFormat:(POBAdFormat)adFormat;

@end
