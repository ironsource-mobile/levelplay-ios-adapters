#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISMobileFuseRewardedVideoAdapter.h"
#import <MobileFuseSDK/MobileFuse.h>
#import <MobileFuseSDK/MFRewardedAd.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>


@interface ISMobileFuseRewardedVideoDelegate : NSObject <IMFAdCallbackReceiver>

@property (nonatomic, strong)   NSString                             *placementId;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>   delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
