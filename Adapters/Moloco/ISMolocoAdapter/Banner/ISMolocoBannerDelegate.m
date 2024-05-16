//
//  ISMolocoBannerDelegate.m
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISMolocoBannerDelegate.h"
#import "ISMolocoBannerAdapter.h"

@implementation ISMolocoBannerDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad was successfully loaded
/// @param ad ad object that was loaded
- (void)didLoadWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    MolocoBannerAdView *bannerAdView = (MolocoBannerAdView *)ad;
    
    [self.delegate adapterBannerDidLoad:bannerAdView];
}

/// calls this method when ad was not loaded for some reasons
/// @param ad ad object that was loaded
/// @param error the reason of failing loading
- (void)failToLoadWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = error.code == MolocoErrorAdLoadFailed ? [ISError createError:ERROR_BN_LOAD_NO_FILL
                                                                        withMessage:@"Moloco no fill"] : error;
    [self.delegate adapterBannerDidFailToLoadWithError:smashError];
}

/// calls this method when ad was shown on screen
/// @param ad ad object that was shown
- (void)didShowWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidShow];
}

/// calls this method when ad fails to show for some reasons
/// @param ad ad object that was not shown
/// @param error the reason of failing loading
- (void)failToShowWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    // TODO ask about show failed error in our sdk
    NSError *smashError = error.code == MolocoErrorAdShowFailed ? [ISError createError:ERROR_BN_LOAD_NO_FILL
                                                                        withMessage:@"Moloco no fill"] : error;
    [self.delegate adapterBannerDidFailToShowWithError:smashError];
}

/// calls this method when user clicked on the ad
/// @param ad ad object that was clicked
- (void)didClickOn:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidClick];
}

/// calls this method when ad was closed
/// @param ad ad object that was closed
- (void)didHideWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

@end
