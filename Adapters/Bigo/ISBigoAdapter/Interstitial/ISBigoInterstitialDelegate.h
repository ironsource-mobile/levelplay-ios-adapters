#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISBigoInterstitialAdapter.h"
#import <BigoADS/BigoInterstitialAdLoader.h>


@interface ISBigoInterstitialDelegate : NSObject <BigoInterstitialAdLoaderDelegate, BigoAdInteractionDelegate>

@property (nonatomic, strong)   NSString                            *slotId;
@property (nonatomic, weak)     ISBigoInterstitialAdapter           *adapter;
@property (nonatomic, weak)     id<ISInterstitialAdapterDelegate>   delegate;

- (instancetype)initWithSlotId:(NSString *)adUnitId
                    andInterstitialAdapter:(ISBigoInterstitialAdapter *)adapter
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
