#import "ISOguryAdapter.h"
#import "ISOguryConstants.h"
#import <OgurySdk/Ogury.h>

@interface ISOguryAdapter()

- (void)initSDKWithAssetKey:(NSString *)appKey;

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (InitState)getInitState;

typedef NS_ENUM(NSInteger, AdState) {
    AD_STATE_NONE,
    AD_STATE_LOAD,
    AD_STATE_SHOW
};
@end
