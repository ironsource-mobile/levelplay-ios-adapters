//
//  ISYandexAdapter+Internal.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"
@import YandexMobileAds;

@interface ISYandexAdapter()

- (void)collectBiddingDataWithRequestConfiguration:(YMABidderTokenRequest *)requestConfiguration
                                          delegate:(id<ISBiddingDataDelegate>)delegate;

- (NSDictionary *)getConfigParams;

- (YMAAdRequest *)createAdRequestWithBidResponse:(NSString *)bidResponse
                                        adUnitId:(NSString *)adUnitId;

+ (NSString *)buildCreativeIdStringFromCreatives:(NSArray<YMACreative *> *)creatives;

@end
