//
//  ISMintegralAdapter+Internal.h
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBiddingDataProtocol.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import "ISMintegralAdapter.h"
#import "ISMintegralConstants.h"

@interface ISMintegralAdapter ()

- (void)collectBiddingDataWithPlacementId:(NSString *)placementId
                                   unitId:(NSString *)unitId
                                   adType:(MintegralAdType)adType
                                 delegate:(id<ISBiddingDataDelegate>)delegate;

@end
