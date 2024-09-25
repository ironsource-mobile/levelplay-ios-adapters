
#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <MobileFuseSdk/MobileFuse.h>
#import <MobileFuseSdk/IMFAdCallbackReceiver.h>

@interface ISMobileFuseBannerDelegate : NSObject <IMFAdCallbackReceiver>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate;
@end
