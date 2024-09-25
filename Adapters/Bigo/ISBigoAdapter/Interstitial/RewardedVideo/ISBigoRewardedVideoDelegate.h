#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISBigoRewardedVideoAdapter.h"
#import <BigoADS/BigoRewardVideoAdLoader.h>


@interface ISBigoRewardedVideoDelegate : NSObject <BigoRewardVideoAdLoaderDelegate, BigoRewardVideoAdInteractionDelegate>

@property (nonatomic, strong)   NSString                             *slotId;
@property (nonatomic, weak)     ISBigoRewardedVideoAdapter           *adapter;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>   delegate;

- (instancetype)initWithSlotId:(NSString *)adUnitId
              andRewardedAdapter:(ISBigoRewardedVideoAdapter *)adapter
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
