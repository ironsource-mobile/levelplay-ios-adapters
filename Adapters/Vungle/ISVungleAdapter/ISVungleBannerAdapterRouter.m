//
//  ISVungleBannerAdapterRouter.m
//  ISVungleAdapter
//
//  Copyright © 2020 ironSource. All rights reserved.
//

#import "ISVungleBannerAdapterRouter.h"
#import "ISVungleAdapter.h"

@interface ISVungleBannerAdapterRouter ()

@property (nonatomic, strong, nullable) NSString *bidPayload;

@end

@implementation ISVungleBannerAdapterRouter

- (instancetype)initWithPlacementID:(NSString *)placementID
                           delegate:(id<ISBannerAdapterDelegate>)delegate {
    if (self = [super init]) {
        _placementID = placementID;
        _delegate = delegate;
        _bannerState = UNKNOWN;
        _bidPayload = nil;
        _bannerSize = BannerSizeRegular;
    }

    return self;
}

- (void)loadBannerAd {
    self.bannerAd = [[VungleBanner alloc] initWithPlacementId:self.placementID size:self.bannerSize];
    self.bannerAd.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.adView = [[UIView alloc] initWithFrame:[self getAdViewRect:self.bannerSize]];
    });

    // Because there's no auto-caching in 7.0 VungleAds,the Ad would
    // never be ready until a load call is made. We don't need to
    // check [VungleBanner canPlayAd] here.
    [self.bannerAd load:self.bidPayload];
}

- (void)showBannerAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bannerAd presentOn:self.adView];
    });
    self.bannerState = SHOWING;
}

- (void)setBidPayload:(NSString * _Nullable)bidPayload {
    _bidPayload = bidPayload;
}

- (void)setSize:(ISBannerSize *)size {
    self.bannerSize = [self getBannerSize:size];
}

- (void)destroy {
    [self.adView removeFromSuperview];
    self.adView = nil;
    self.bannerAd.delegate = nil;
    self.bannerAd = nil;
}

- (void)bannerAdInitSuccess {
    [self.delegate adapterBannerInitSuccess];
}

- (void)bannerAdInitFailed:(NSError *)error {
    [self.delegate adapterBannerInitFailedWithError:error];
}

#pragma mark - Helper

- (BannerSize)getBannerSize:(ISBannerSize *)size {
    BannerSize vungleAdSize = BannerSizeRegular;

    if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        vungleAdSize = BannerSizeMrec;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            vungleAdSize = BannerSizeLeaderboard;
        } else {
            vungleAdSize = BannerSizeRegular;
        }
    }

    return vungleAdSize;
}

- (CGRect)getAdViewRect:(BannerSize)bannerSize {
    CGRect rect = CGRectMake(0, 0, 320, 50);
    switch (bannerSize) {
        case BannerSizeShort:
            rect = CGRectMake(0, 0, 300, 50);
            break;
        case BannerSizeLeaderboard:
            rect = CGRectMake(0, 0, 728, 90);
            break;
        case BannerSizeMrec:
            rect = CGRectMake(0, 0, 300, 250);
            break;
        default:
            break;
    }

    return rect;
}

- (NSString *)getBannerStateString:(BANNER_STATE)state {
    switch (state) {
        case UNKNOWN:
            return @"UNKNOWN";
        case REQUESTING:
            return @"REQUESTING";
        case SHOWING:
            return @"SHOWING";
    }

    return @"UNKNOWN";
}

#pragma mark - VungleBannerDelegate

- (void)bannerAdDidLoad:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@, currentBannerState = %@", banner.placementId, [self getBannerStateString:self.bannerState]);

    if (self.bannerState == REQUESTING) {
        if (![banner canPlayAd]) {
            // When Banner Ad is loaded the canPlayAd should also return YES
            // If for some reason that is not the case we might want to not show the banner
            LogAdapterDelegate_Internal(@"Vungle Banner Ad is loaded but not ready to be shown");

            // update Banner state - UNKNOWN
            self.bannerState = UNKNOWN;
            NSError *error = [ISError createError:ERROR_BN_LOAD_NO_FILL
                                           withMessage:[NSString stringWithFormat:@"Vungle - banner no ads to show for placementID = %@", banner.placementId]];
            [self.delegate adapterBannerDidFailToLoadWithError:error];
            return;
        }

        [self showBannerAd];
        [self.delegate adapterBannerDidLoad:self.adView];
    }
}

- (void)bannerAdDidFailToLoad:(VungleBanner * _Nonnull)banner withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementID = %@, error = %@", banner.placementId, error);

    // update Banner state - UNKNOWN
    self.bannerState = UNKNOWN;
    NSError *smashError = [ISError createError:ERROR_BN_LOAD_NO_FILL
                                   withMessage:[NSString stringWithFormat:@"Vungle - banner no ads to show for placementID = %@", banner.placementId]];
    [self.delegate adapterBannerDidFailToLoadWithError:smashError];
}

- (void)bannerAdDidTrackImpression:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@", banner.placementId);
    [self.delegate adapterBannerDidShow];
}

- (void)bannerAdDidClose:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@, currentBannerState = %@", banner.placementId, [self getBannerStateString:self.bannerState]);
    [self.delegate adapterBannerDidDismissScreen];
}

- (void)bannerAdDidClick:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@", banner.placementId);
    [self.delegate adapterBannerDidClick];
}

- (void)bannerAdWillLeaveApplication:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@", banner.placementId);
    [self.delegate  adapterBannerWillLeaveApplication];
}

- (void)bannerAdWillPresent:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@", banner.placementId);
    [self.delegate adapterBannerWillPresentScreen];
}

- (void)bannerAdDidPresent:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@", banner.placementId);
}
- (void)bannerAdWillClose:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementID = %@", banner.placementId);
}

- (void)bannerAdDidFailToPresent:(VungleBanner * _Nonnull)banner withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementID = %@, error = %@", banner.placementId, error);
}

@end
