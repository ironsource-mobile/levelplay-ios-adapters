#import "ISFacebookAdapter.h"
#import "ISFacebookConstants.h"

@interface ISFacebookAdapter()

- (void)initSDKWithPlacementIds:(NSString *)allPlacementIds;

- (NSDictionary *)getBiddingData;

- (InitState)getInitState;

@end
