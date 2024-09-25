#import "ISMobileFuseBannerDelegate.h"
#import "ISMobileFuseBannerAdapter.h"

@implementation ISMobileFuseBannerDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}

/// Ad has loaded - you are able to show the ad after this callback is triggered
- (void)onAdLoaded:(MFAd *)ad {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);

    [self.delegate adapterBannerDidLoad:ad];
    [ad showAd];
}

/// No ad is currently available to display to this user
- (void)onAdNotFilled:(MFAd *)ad {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    NSError *smashError = [ISError createError:ERROR_RV_LOAD_NO_FILL
                                   withMessage:@"MobileFuse no fill"];
    [self.delegate adapterBannerDidFailToLoadWithError:smashError];
}

- (void)onAdError:(MFAd *)ad withError:(MFAdError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@ with error = %@", self.placementId, error);
    [self.delegate adapterBannerDidFailToLoadWithError:error];
}

/// Triggered when the ad begins to show to the user
- (void)onAdRendered:(MFAd *)ad {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidShow];
}

/// Triggered when the ad is clicked by the user
- (void)onAdClicked:(MFAd *)ad {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidClick];
}

/// Triggered when a loaded ad has expired - you should manually try to load a new ad here
- (void)onAdExpired:(MFAd *)ad {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
}

@end
