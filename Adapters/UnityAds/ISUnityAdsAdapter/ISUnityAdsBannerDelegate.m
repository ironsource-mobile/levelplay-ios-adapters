//
//  ISUnityAdsBannerDelegate.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <ISUnityAdsBannerDelegate.h>

@interface ISUnityAdsBannerDelegate()
@property (nonatomic, copy) ISUnityAdsEventSenderBlock _Nullable eventSender;
@end

@implementation ISUnityAdsBannerDelegate

- (instancetype) initWithDelegate:(id<ISUnityAdsBannerDelegateWrapper>)delegate
                      eventSender:(ISUnityAdsEventSenderBlock)eventSender {
    self = [super init];

    if (self) {
        _delegate = delegate;
        self.eventSender = eventSender;
    }

    return self;
}

#pragma mark UADSBannerViewDelegate

/**
 * Called when the banner is loaded and ready to be placed in the view hierarchy.
 * @param bannerView View that was loaded
 */
- (void) bannerViewDidLoad:(UADSBannerView * _Nonnull)bannerView {
    if (_delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_BANNER, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"banner_onBannerLoaded");
    }
    [_delegate onBannerDidLoad:bannerView];
}

/**
 * Called when the banner is showed
 * @param bannerView View that was showed
 */
- (void) bannerViewDidShow:(UADSBannerView * _Nonnull)bannerView {
    if (_delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_BANNER, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"banner_onBannerShown");
    }
    [_delegate onBannerDidShow:bannerView];
}

/**
 *  Called when `UnityAdsBanner` encounters an error. All errors will be logged but this method can be used as an additional debugging aid. This callback can also be used for collecting statistics from different error scenarios.
 *  @param bannerView View that encountered an error.
 *  @param error UADSBannerError that occurred
 */
- (void) bannerViewDidError:(UADSBannerView * _Nonnull)bannerView
                      error:(UADSBannerError * _Nullable)error {
    if (_delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_BANNER, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"banner_onBannerFailedToLoad");
    }
    [_delegate onBannerDidFailToLoad:bannerView
                           withError:error];
}

/**
 * Called when the user clicks the banner.
 * @param bannerView View that the click occurred on.
 */
- (void) bannerViewDidClick:(UADSBannerView * _Nonnull)bannerView {
    if (_delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_BANNER, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"banner_onBannerClick");
    }
    [_delegate onBannerDidClick:bannerView];
}

/**
 * Called when a banner click triggers leaving the application
 * @param bannerView View that triggered leaving application
 */
- (void) bannerViewDidLeaveApplication:(UADSBannerView * _Nonnull)bannerView {
    if (_delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_BANNER, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"banner_onBannerLeftApplication");
    }
    [_delegate onBannerWillLeaveApplication:bannerView];
}

@end
