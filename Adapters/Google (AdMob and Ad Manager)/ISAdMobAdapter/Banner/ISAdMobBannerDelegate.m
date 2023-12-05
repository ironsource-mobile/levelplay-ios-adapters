//
//  ISAdMobBannerDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#include "ISAdMobBannerAdapter.h"
#include "ISAdMobBannerDelegate.h"

@implementation ISAdMobBannerDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Tells the delegate that an ad request successfully received an ad. The delegate may want to add
/// the banner view to the view hierarchy if it hasn't been added yet.
- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidLoad:bannerView];
}

/// Tells the delegate that an ad request failed. The failure is normally due to network
/// connectivity or ad availablility (i.e., no fill).
- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = (error.code == GADErrorNoFill || error.code == GADErrorMediationNoFill) ? [ISError createError:ERROR_BN_LOAD_NO_FILL
                                                                                                             withMessage:@"AdMob no fill"] : error;
    [self.delegate adapterBannerDidFailToLoadWithError:smashError];
}

/// Tells the delegate that an impression has been recorded for an ad.
- (void)bannerViewDidRecordImpression:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidShow];
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)bannerViewDidRecordClick:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidClick];
}

#pragma mark  Click-Time Lifecycle Notifications
/// Tells the delegate that a full screen view will be presented in response to the user clicking on
/// an ad. The delegate may want to pause animations and time sensitive interactions.
- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerWillPresentScreen];
}

/// Tells the delegate that the full screen view will be dismissed.
- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// Tells the delegate that the full screen view has been dismissed. The delegate should restart
/// anything paused while handling adViewWillPresentScreen:.
- (void)bannerViewDidDismissScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidDismissScreen];
}



@end
