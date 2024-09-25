#import "ISBigoAdapter.h"
#import "ISBigoConstants.h"
#import <BigoADS/BigoAdSdk.h>

@interface ISBigoAdapter()

- (void)initSDKWithAppKey:(NSString *)appKey;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

@end
