#import <Foundation/Foundation.h>
#import "ISOguryAdapter+Internal.h"
#import <OgurySdk/Ogury.h>
#import <IronSource/IronSource.h>

@interface ISOguryBannerAdapter : ISBaseBannerAdapter

- (instancetype)initWithOguryAdapter:(ISOguryAdapter *)adapter;

- (void)removeBannerAd;

@end

