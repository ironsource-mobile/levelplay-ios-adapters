//
//  ISVungleBannerAdapterRouter.h
//  ISVungleAdapter
//
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import "IronSource/ISBaseAdapter+Internal.h"

NS_ASSUME_NONNULL_BEGIN

// Banner state possible values
typedef NS_ENUM(NSUInteger, BANNER_STATE) {
    UNKNOWN,
    REQUESTING,
    REQUESTING_RELOAD,
    SHOWING
};

@class ISVungleAdapter;
@interface ISVungleBannerAdapterRouter : NSObject<VungleBannerDelegate>

@property (nonatomic, strong) NSString *placementID;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;
@property (nonatomic, strong, nullable) UIView *adView;
@property (nonatomic, strong, nullable) VungleBanner *bannerAd;
@property (nonatomic, assign) BannerSize bannerSize;
@property (nonatomic, assign) BANNER_STATE bannerState;

- (instancetype)initWithPlacementID:(NSString *)placementID
                           delegate:(id<ISBannerAdapterDelegate>)delegate;

- (void)loadBannerAd;
- (void)showBannerAd;
- (void)setBidPayload:(NSString * _Nullable)bidPayload;
- (void)setSize:(ISBannerSize *)size;
- (void)destroy;

- (void)bannerAdInitSuccess;
- (void)bannerAdInitFailed:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
