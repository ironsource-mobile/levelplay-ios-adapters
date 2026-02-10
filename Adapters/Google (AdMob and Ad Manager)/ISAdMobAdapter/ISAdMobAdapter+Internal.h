#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"

@interface ISAdMobAdapter ()

- (void)initAdMobSDKWithAdapterConfig:(ISAdapterConfig *)adapterConfig;

- (void)collectBiddingDataWithAdFormat:(GADAdFormat)adFormat
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                                adData:(NSDictionary *)adData
                              delegate:(id<ISBiddingDataDelegate>)delegate;

- (GADRequest *)createGADRequestWithAdData:(NSDictionary *)adData;

- (InitState)getInitState;

@end
