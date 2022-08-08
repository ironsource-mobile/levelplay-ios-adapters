//
//  ISUnityAdsBannerListener.m
//  ISUnityAdsAdapter
//
//  Created by Roi Eshel on 02/11/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#import "ISUnityAdsBannerListener.h"

@implementation ISUnityAdsBannerListener

- (instancetype) initWithDelegate:(id<ISUnityAdsBannerDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark UADSBannerViewDelegate

/**
 * Called when the banner is loaded and ready to be placed in the view hierarchy.
 *
 * @param bannerView View that was loaded
 */
- (void) bannerViewDidLoad:(UADSBannerView * _Nonnull)bannerView {
    [_delegate onBannerLoadSuccess:bannerView];
}

/**
 *  Called when `UnityAdsBanner` encounters an error. All errors will be logged but this method can be used as an additional debugging aid. This callback can also be used for collecting statistics from different error scenarios.
 *
 *  @param bannerView View that encountered an error.
 *  @param error UADSBannerError that occurred
 */
- (void) bannerViewDidError:(UADSBannerView * _Nonnull)bannerView
                      error:(UADSBannerError * _Nullable)error {
    [_delegate onBannerLoadFail:bannerView
                      withError:error];
}

/**
 * Called when the user clicks the banner.
 *
 * @param bannerView View that the click occurred on.
 */
- (void) bannerViewDidClick:(UADSBannerView * _Nonnull)bannerView {
    [_delegate onBannerDidClick:bannerView];
}

/**
 * Called when a banner click triggers leaving the application
 *
 * @param bannerView View that triggered leaving application
 */
- (void) bannerViewDidLeaveApplication:(UADSBannerView * _Nonnull)bannerView {
    [_delegate onBannerWillLeaveApplication:bannerView];
}

@end
