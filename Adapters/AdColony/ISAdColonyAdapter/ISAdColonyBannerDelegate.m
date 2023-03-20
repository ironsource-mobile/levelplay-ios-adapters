//
//  ISAdColonyBannerDelegate.m
//  ISAdColonyAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISAdColonyBannerDelegate.h>

@implementation ISAdColonyBannerDelegate

- (instancetype)initWithZoneId:(NSString *)zoneId
                   andDelegate:(id<ISAdColonyBannerDelegateWrapper> )delegate {
    self = [super init];
    
    if (self) {
        _zoneId = zoneId;
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark AdColonyInterstitialDelegate

/**
 @abstract Did load notification
 @discussion Notifies you when ad view has been created, received the ad and is ready to use. Call is dispatched on main thread.
 @param adView Loaded ad view
 */
- (void)adColonyAdViewDidLoad:(AdColonyAdView * _Nonnull)adView {
    [_delegate onBannerDidLoad:adView
                     forZoneId:_zoneId];
}

/**
 @abstract No ad notification
 @discussion Notifies you when SDK was not able to load the ad for requested zone. Call is dispatched on main thread.
 @param error Error with failure explanation
 */
- (void)adColonyAdViewDidFailToLoad:(AdColonyAdRequestError * _Nonnull)error {
    [_delegate onBannerDidFailToLoad:_zoneId
                           withError:error];
}

/**
 @abstract Did show notification
 @discussion Ad view was added to a view with active window
 @param adView Shown ad view
 */
- (void)adColonyAdViewDidShow:(AdColonyAdView * _Nonnull)adView {
    [_delegate onBannerDidShow:_zoneId];
}

/**
 @abstract Received a click notification
 @discussion Notifies you when adView receives a click
 @param adView Ad view that received a click
 */
- (void)adColonyAdViewDidReceiveClick:(AdColonyAdView * _Nonnull)adView {
    [_delegate onBannerDidClick:adView
                      forZoneId:_zoneId];
}

/**
 @abstract Application leave notification
 @discussion Notifies you when ad view is going to redirect user to content outside of the application.
 @param adView The ad view which caused the user to leave the application.
 */
- (void)adColonyAdViewWillLeaveApplication:(AdColonyAdView * _Nonnull)adView {
    [_delegate onBannerBannerWillLeaveApplication:adView
                                        forZoneId:_zoneId];
}

/**
 @abstract Open fullscreen content notification
 @discussion Notifies you when ad view is going to display fullscreen content. Call is dispatched on worker thread.
 @param adView Ad view that is going to display fullscreen content.
 */
- (void)adColonyAdViewWillOpen:(AdColonyAdView * _Nonnull)adView {
    [_delegate onBannerBannerWillPresentScreen:adView
                                     forZoneId:_zoneId];
}

/**
 @abstract Did close fullscreen content notification
 @discussion Notifies you when ad view stopped displaying fullscreen content
 @param adView Ad view that stopped displaying fullscreen content
 */
- (void)adColonyAdViewDidClose:(AdColonyAdView * _Nonnull)adView {
    [_delegate onBannerBannerDidDismissScreen:adView
                                    forZoneId:_zoneId];
}

@end
