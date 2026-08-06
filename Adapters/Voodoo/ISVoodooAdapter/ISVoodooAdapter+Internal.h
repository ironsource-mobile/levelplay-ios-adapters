//
//  ISVoodooAdapter+Internal.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVoodooAdapter.h"
#import "ISVoodooConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBiddingDataProtocol.h>
#import <VoodooAdn/VoodooAdn.h>

@interface ISVoodooAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                         placementType:(AdnPlacementType)placementType;

@end
