//
//  ISLineAdapter+Internal.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISLineAdapter.h"
#import "ISLineConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBiddingDataProtocol.h>
#import <FiveAd/FiveAd.h>

@interface ISLineAdapter ()

- (FADAdLoader *)getAdLoader:(NSString *)appId;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                                 appId:(NSString *)appId
                                slotId:(NSString *)slotId;

@end
