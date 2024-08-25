//
//  ISVerveBannerDelegate.m
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISVerveBannerDelegate.h"
#import "ISVerveBannerAdapter.h"

@implementation ISVerveBannerDelegate

- (instancetype)initWithZoneId:(NSString *)zoneId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _zoneId = zoneId;
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad successfully loaded and ready to be displayed.
/// @param adView adView object that was loaded
- (void)adViewDidLoad:(HyBidAdView *)adView {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterBannerDidLoad:adView];
}
/// calls this method when ad was not loaded for some reasons
/// @param adView adView object that was loaded
/// @param error the reason of failing loading
- (void)adView:(HyBidAdView *)adView didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@ with error = %@", self.zoneId, error);
    NSError *smashError = error.code == HyBidErrorCodeNoFill ? [ISError createError:ERROR_BN_LOAD_NO_FILL
                                        withMessage:@"Verve no fill"] : error;
    
    [self.delegate adapterBannerDidFailToLoadWithError:smashError];

}

/// calls this method when user clicked on the ad
/// @param adView adView object that was clicked
- (void)adViewDidTrackClick:(HyBidAdView *)adView {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterBannerDidClick];
}
/// calls this method when ad was displayed and is viewable by the user
- (void)adViewDidTrackImpression:(HyBidAdView *)adView {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterBannerDidShow];
}

@end
