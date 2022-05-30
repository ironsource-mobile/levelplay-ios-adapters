//
//  ISAdMobBannerListener.m
//  ISAdMobAdapter
//
//  Created by maoz.elbaz on 21/05/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//


#include "ISAdMobBannerListener.h"

@implementation ISAdMobBannerListener

- (instancetype)initWithAdUnitId:(NSString *)adUnitId andDelegate:(id<ISAdMobBannerDelegateWrapper>)delegate {
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
    [_delegate onBannerLoadSuccess:bannerView];
}

/// Tells the delegate that an ad request failed. The failure is normally due to network
/// connectivity or ad availablility (i.e., no fill).
- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(nonnull NSError *)error {
    [_delegate onBannerLoadFail:_adUnitId withError:error];
}

/// Tells the delegate that an impression has been recorded for an ad.
- (void)bannerViewDidRecordImpression:(nonnull GADBannerView *)bannerView {
    [_delegate onBannerDidShow:_adUnitId];
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)bannerViewDidRecordClick:(nonnull GADBannerView *)bannerView; {
    [_delegate onBannerDidClick:_adUnitId];
}

#pragma mark  Click-Time Lifecycle Notifications
/// Tells the delegate that a full screen view will be presented in response to the user clicking on
/// an ad. The delegate may want to pause animations and time sensitive interactions.
- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView {
    [_delegate onBannerWillPresentScreen:_adUnitId];
}

/// Tells the delegate that the full screen view will be dismissed.
- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView {
}

/// Tells the delegate that the full screen view has been dismissed. The delegate should restart
/// anything paused while handling adViewWillPresentScreen:.
- (void)bannerViewDidDismissScreen:(GADBannerView *)bannerView {
    [_delegate onBannerDidDismissScreen:_adUnitId];
}



@end
