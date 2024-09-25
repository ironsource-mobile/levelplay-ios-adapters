#import <Foundation/Foundation.h>
#import "ISBigoAdapter+Internal.h"
#import <BigoADS/BigoRewardVideoAd.h>

@interface ISBigoRewardedVideoAdapter : ISBaseRewardedVideoAdapter

- (instancetype)initWithBigoAdapter:(ISBigoAdapter *)adapter;

- (void)setRewardedAd:(BigoRewardVideoAd *)ad;

@end
