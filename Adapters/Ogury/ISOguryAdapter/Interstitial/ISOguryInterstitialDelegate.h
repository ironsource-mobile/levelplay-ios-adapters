#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISOguryInterstitialAdapter.h"
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@interface ISOguryInterstitialDelegate : NSObject <OguryInterstitialAdDelegate>

@property (nonatomic, strong)   NSString                            *adUnitId;
@property (nonatomic, weak)     id<ISInterstitialAdapterDelegate>   delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
