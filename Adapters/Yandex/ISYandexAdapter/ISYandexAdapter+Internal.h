//
//  ISYandexAdapter+Internal.h
//  ISYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"
#import "YandexMobileAds/YandexMobileAds.h"

@interface ISYandexAdapter()

- (void)initSDKWithAppId:(NSString *)appId;

- (void)collectBiddingDataWithRequestConfiguration:(YMABidderTokenRequestConfiguration *)requestConfiguration
                                          delegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

- (NSDictionary *)getConfigParams;

- (YMAMutableAdRequest *)createAdRequestWithBidResponse:(NSString *)bidResponse;

- (YMAMutableAdRequestConfiguration *)createAdRequestWithBidResponse:(NSString *)bidResponse
                                                            adUnitId:(NSString *)adUnitId;

@end

