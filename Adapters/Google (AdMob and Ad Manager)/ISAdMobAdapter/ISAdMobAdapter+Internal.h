//
//  ISAdMobAdapter+Internal.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"
#import <IronSource/ISBiddingDataProtocol.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ISAdMobAdapter ()

- (GADRequest *)createGADRequestWithAdData:(NSDictionary *)adData;

- (void)collectBiddingDataWithSignalRequest:(GADSignalRequest *)request
                                     adData:(ISAdData *)adData
                                   delegate:(id<ISBiddingDataDelegate>)delegate;

@end
