#import <Foundation/Foundation.h>
#import "ISBigoAdapter+Internal.h"
#import <BigoADS/BigoBannerAdLoader.h>
#import <BigoADS/BigoAdSize.h>


@interface ISBigoBannerAdapter : ISBaseBannerAdapter

- (instancetype)initWithBigoAdapter:(ISBigoAdapter *)adapter;

- (void)setBannerAd:(BigoBannerAd *)ad;

@end

