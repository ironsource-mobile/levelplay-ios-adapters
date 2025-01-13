//
//  ISAppLovinInterstitialDelegate.m
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISAppLovinInterstitialDelegate.h>

@implementation ISAppLovinInterstitialDelegate


- (instancetype)initWithZoneId:(NSString *)zoneId
                        adapter:(ISAppLovinAdapter *)adapter
                      delegate:(id<ISAppLovinInterstitialDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        _zoneId = zoneId;
        _adapter = adapter;
        _delegate = delegate;
    }
    
    return self;
}


#pragma mark - ALAdLoadDelegate

/**
 * The SDK invokes this method when an ad is loaded by the AdService.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param adService AdService that loaded the ad.
 * @param ad        Ad that was loaded.
 */
- (void)adService:(ALAdService *)adService
        didLoadAd:(ALAd *)ad {
    [_delegate onInterstitialDidLoad:_zoneId
                              adView:ad];
}

/**
 * The SDK invokes this method when an ad load fails.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param adService AdService that failed to load an ad.
 * @param code      An error code that corresponds to one of the constants defined in ALErrorCodes.h.
 */
- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    [_adapter disposeInterstitialAdWithZoneId:_zoneId];
    [_delegate onInterstitialDidFailToLoad:_zoneId
                                 errorCode:code];
}

#pragma mark - ALAdDisplayDelegate

/**
 * The SDK invokes this when the ad is displayed in the view.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad    Ad that was just displayed.
 * @param view  Ad view in which the ad was displayed.
 */
- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    [_delegate onInterstitialDidOpen:_zoneId];
}

/**
 * The SDK invokes this method when the ad is clicked in the view.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad    Ad that was just clicked.
 * @param view  Ad view in which the ad was clicked.
 */
- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
    [_delegate onInterstitialDidClick:_zoneId];
}

/**
 * The SDK invokes this method when the ad is hidden from the view. This occurs when the user "X"es out of an interstitial.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad    Ad that was just hidden.
 * @param view  Ad view in which the ad was hidden.
 */
- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    [_adapter disposeInterstitialAdWithZoneId:_zoneId];
    [_delegate onInterstitialDidClose:_zoneId];
}

@end
