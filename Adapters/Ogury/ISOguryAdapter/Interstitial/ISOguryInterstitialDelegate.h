#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISOguryInterstitialAdapter.h"
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@interface ISOguryInterstitialDelegate : NSObject <OguryInterstitialAdDelegate>

@property (nonatomic, strong)   NSString                            *adUnitId;
@property (nonatomic, weak)     id<ISInterstitialAdapterDelegate>   delegate;
@property (nonatomic, assign)   AdState                             adState;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                    adState:(AdState)adState
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
