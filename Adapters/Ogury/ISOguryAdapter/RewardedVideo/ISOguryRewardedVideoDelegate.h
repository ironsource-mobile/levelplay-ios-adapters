#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISOguryRewardedVideoAdapter.h"
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@interface ISOguryRewardedVideoDelegate : NSObject <OguryOptinVideoAdDelegate>

@property (nonatomic, strong)   NSString                             *adUnitId;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>   delegate;
@property (nonatomic, assign)   AdState                              adState;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                         adState:(AdState)adState
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
