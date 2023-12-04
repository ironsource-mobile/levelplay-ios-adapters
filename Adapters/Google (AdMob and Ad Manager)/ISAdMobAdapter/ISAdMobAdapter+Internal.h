#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"

@interface ISAdMobAdapter ()

- (void)initAdMobSDKWithAdapterConfig:(ISAdapterConfig *)adapterConfig;

- (void)collectBiddingDataWithAdData:(GADRequest *)request
                            adFormat:(GADAdFormat)adFormat
                            delegate:(id<ISBiddingDataDelegate>)delegate;

- (GADRequest *)createGADRequestForLoadWithAdData:(NSDictionary *)adData
                                       serverData:(NSString *)serverData;

- (InitState)getInitState;

@end
