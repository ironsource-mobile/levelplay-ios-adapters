//
//  ISMyTargetInterstitialListener.m
//  ISMyTargetAdapter
//
//  Created by Hadar Pur on 14/07/2020.
//

#import "ISMyTargetInterstitialListener.h"

@implementation ISMyTargetInterstitialListener

- (instancetype)initWithDelegate:(id<ISMyTargetInterstitialDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/**
 *  Called when the ad is successfully load , and is ready to be displayed
 */
- (void)onLoadWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    [_delegate onInterstitialLoadSuccess:interstitialAd];
}

/**
 *  Called when there was an error loading the ad.
 *  @param reason       - reasont that describes the exact error encountered when loading the ad.
 */
- (void)onNoAdWithReason:(NSString *)reason interstitialAd:(MTRGInterstitialAd *)interstitialAd {
    [_delegate onInterstitialLoadFailWithReason:reason interstitialAd:interstitialAd];
}


/**
 *  Called when the ad is clicked
 */
- (void)onClickWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    [_delegate onInterstitialClicked:interstitialAd];
}

/**
 *  Called when the ad display success
 */
- (void)onDisplayWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDisplay:interstitialAd];
}


/**
 *  Called when the ad  did closed
 */
- (void)onCloseWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    [_delegate onInterstitialClosed:interstitialAd];
}

/**
 *  Called when the ad  did complited
 */
- (void)onVideoCompleteWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    [_delegate onInterstitialCompleted:interstitialAd];
}

@end

