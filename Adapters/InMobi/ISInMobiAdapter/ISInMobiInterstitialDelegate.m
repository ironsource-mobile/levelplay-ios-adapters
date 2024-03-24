//
//  ISInMobiInterstitialDelegate.m
//  ISInMobiAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISInMobiInterstitialDelegate.h>

@implementation ISInMobiInterstitialDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISInMobiInterstitialDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark IMInterstitialDelegate

/**
 Called when the IMInterstitial object loads successfully.
 @param interstitial IMInterstitial object that was loaded successfully.
 */
- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [self.delegate onInterstitialDidLoad:(IMInterstitial *)interstitial
                             placementId:self.placementId];
}

/**
 Called when the IMInterstitial fails to load.
 @param interstitial IMInterstitial object that failed to load.
 @param error An error object containing details of the error.
 */
- (void)interstitial:(IMInterstitial *)interstitial
didFailToLoadWithError:(IMRequestStatus *)error {
    [self.delegate onInterstitialDidFailToLoad:interstitial
                                         error:error
                                   placementId:self.placementId];
}

/**
 Called when the IMInterstitial object logs an impression.
 @param interstitial IMInterstitial object that logged an impression.
 */
- (void)interstitialAdImpressed:(IMInterstitial *)interstitial {
    [self.delegate onInterstitialDidOpen:interstitial
                             placementId:self.placementId];
}

/**
 Called when the IMInterstitial fails to load.
 @param interstitial IMInterstitial object that failed to show.
 @param error An error object containing details of the error.
 */
- (void)interstitial:(IMInterstitial *)interstitial
didFailToPresentWithError:(IMRequestStatus *)error {
    [self.delegate onInterstitialDidFailToShow:interstitial
                                         error:error
                                   placementId:self.placementId];
}

/**
 Called when the IMInterstitial did dismiss.
 @param interstitial IMInterstitial object that failed to show.
 */
- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [self.delegate onInterstitialDidClose:interstitial
                              placementId:self.placementId];
}

/**
 Called when the IMInterstitial object was clicked.
 @param interstitial IMInterstitial object that was clicked.
 @param params additional data regarding the click.
 */
- (void)interstitial:(IMInterstitial *)interstitial
didInteractWithParams:(NSDictionary *)params {
    [self.delegate onInterstitialDidClick:interstitial
                                   params:params
                              placementId:self.placementId];
}

@end
