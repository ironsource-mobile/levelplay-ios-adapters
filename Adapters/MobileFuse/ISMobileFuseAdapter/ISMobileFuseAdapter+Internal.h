#import "ISMobileFuseAdapter.h"
#import "ISMobileFuseConstants.h"
#import <MobileFuseSDK/MobileFuse.h>

@interface ISMobileFuseAdapter()

- (void)initSDKWithPlacementId:(NSString *)placementId;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

@end
