
#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISBigoBannerAdapter.h"
#import <BigoADS/BigoBannerAdLoader.h>


@interface ISBigoBannerDelegate : NSObject <BigoBannerAdLoaderDelegate, BigoAdInteractionDelegate>

@property (nonatomic, strong) NSString* slotId;
@property (nonatomic, weak) ISBigoBannerAdapter*        adapter;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithSlotId:(NSString *)adUnitId
                andBannerAdapter:(ISBigoBannerAdapter *)adapter
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate;
@end
