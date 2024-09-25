#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISMobileFuseInterstitialAdapter.h"
#import <MobileFuseSDK/MobileFuse.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>


@interface ISMobileFuseInterstitialDelegate : NSObject <IMFAdCallbackReceiver>

@property (nonatomic, strong)   NSString                            *placementId;
@property (nonatomic, weak)     id<ISInterstitialAdapterDelegate>   delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
