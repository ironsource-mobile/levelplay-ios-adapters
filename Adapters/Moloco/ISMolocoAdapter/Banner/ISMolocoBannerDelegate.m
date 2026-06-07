//
//  ISMolocoBannerDelegate.m
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBaseBanner.h>
#import "ISMolocoBannerDelegate.h"
#import "ISMolocoConstants.h"

@implementation ISMolocoBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// Calls this method when ad was successfully loaded
/// @param ad ad object that was loaded
- (void)didLoadWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    MolocoBannerAdView *bannerAdView = (MolocoBannerAdView *)ad;

    [self.delegate adDidLoadWithView:bannerAdView];
}

/// Calls this method when ad was not loaded for some reasons
/// @param ad ad object that was loaded
/// @param error the reason of failing loading
- (void)failToLoadWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    ISAdapterErrorType errorType = (error.code == MolocoErrorAdLoadFailed) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// Calls this method when ad was shown on screen
/// @param ad ad object that was shown
- (void)didShowWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Calls this method when ad fails to show for some reasons
/// @param ad ad object that was not shown
/// @param error the reason of failing loading
- (void)failToShowWithAd:(id<MolocoAd> _Nonnull)ad with:(NSError * _Nullable)error {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// Calls this method when user clicked on the ad
/// @param ad ad object that was clicked
- (void)didClickOn:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Calls this method when ad was closed
/// @param ad ad object that was closed
- (void)didHideWithAd:(id<MolocoAd> _Nonnull)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
