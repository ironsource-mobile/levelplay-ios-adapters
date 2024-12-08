//
//  ISMolocoInterstitialDelegate.m
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISMolocoInterstitialDelegate.h"

@implementation ISMolocoInterstitialDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
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
    [self.delegate adapterInterstitialDidLoad];
}

/// calls this method when ad was not loaded for some reasons
/// @param ad ad object that was loaded
/// @param error the reason of failing loading
- (void)failToLoadWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = error.code == MolocoErrorAdLoadFailed ? [ISError createError:ERROR_IS_LOAD_NO_FILL
                                                                        withMessage:@"Moloco no fill"] : error;
    [self.delegate adapterInterstitialDidFailToLoadWithError:smashError];
}

/// calls this method when ad was shown on screen
/// @param ad ad object that was shown
- (void)didShowWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

/// calls this method when ad fails to show for some reasons
/// @param ad ad object that was not shown
/// @param error the reason of failing loading
- (void)failToShowWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

/// calls this method when user clicked on the ad
/// @param ad ad object that was clicked
- (void)didClickOn:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClick];
}

/// calls this method when ad was closed
/// @param ad ad object that was closed
- (void)didHideWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClose];
}
@end
