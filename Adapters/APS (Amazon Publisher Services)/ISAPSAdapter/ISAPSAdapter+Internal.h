//
//  ISAPSAdapter+Internal.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAPSAdapter.h"
#import "ISAPSConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@interface ISAPSAdapter ()

- (void)collectBiddingInfoWithSize:(DTBAdSize *)size
                          delegate:(id<ISBiddingDataDelegate>)delegate
                        completion:(void (^)(DTBAdResponse *))completion;

- (DTBAdSize *)createVideoAdSizeWithSlotUUID:(NSString *)slotUUID;

+ (NSString *)errorFromCode:(DTBAdErrorCode)errorCode;

@end
