#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISOguryRewardedVideoAdapter.h"
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@interface ISOguryRewardedVideoDelegate : NSObject <OguryRewardedAdDelegate>

@property (nonatomic, strong)   NSString                             *adUnitId;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>   delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
