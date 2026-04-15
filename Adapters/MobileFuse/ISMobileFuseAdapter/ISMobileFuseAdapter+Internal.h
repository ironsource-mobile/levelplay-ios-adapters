//
//  ISMobileFuseAdapter+Internal.h
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISMobileFuseAdapter.h"
#import "ISMobileFuseConstants.h"
#import <MobileFuseSDK/MobileFuse.h>

@interface ISMobileFuseAdapter ()

- (MobileFusePrivacyPreferences *)getPrivacyData;
- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

@end
