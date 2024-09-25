#import <Foundation/Foundation.h>
#import "ISMobileFuseAdapter+Internal.h"
#import <MobileFuseSdk/MobileFuse.h>
#import <MobileFuseSDK/MFBannerAd.h>


@interface ISMobileFuseBannerAdapter : ISBaseBannerAdapter

- (instancetype)initWithMobileFuseAdapter:(ISMobileFuseAdapter *)adapter;

@end

