
#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>
#import "ISOguryBannerAdapter.h"

@interface ISOguryBannerDelegate : NSObject <OguryBannerAdViewDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, strong) ISOguryBannerAdapter* adapter;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                andBannerAdapter:(ISOguryBannerAdapter *)adapter
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate;
@end
