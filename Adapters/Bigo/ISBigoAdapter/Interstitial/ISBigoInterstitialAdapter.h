#import <Foundation/Foundation.h>
#import "ISBigoAdapter+Internal.h"
#import <BigoADS/BigoInterstitialAd.h>

@interface ISBigoInterstitialAdapter : ISBaseInterstitialAdapter

- (instancetype)initWithBigoAdapter:(ISBigoAdapter *)adapter;

- (void)setInterstitialAd:(BigoInterstitialAd *)ad;

@end

