//
//  ISYandexAdapter+Internal.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
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

