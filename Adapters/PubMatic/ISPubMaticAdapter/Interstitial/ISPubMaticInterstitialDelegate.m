//
//  ISPubMaticInterstitialDelegate.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticInterstitialDelegate.h"

@implementation ISPubMaticInterstitialDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/*!
 @abstract Notifies the delegate that an ad has been received successfully.
 @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialDidReceiveAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidLoad];
}

/*!
 @abstract Notifies the delegate of an error encountered while loading an ad.
 @param interstitial The POBInterstitial instance sending the message.
 @param error The error encountered while loading an ad.
 */
- (void)interstitial:(POBInterstitial *)interstitial didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@, error = %@", self.adUnitId, error);
    
    NSInteger errorCode = (error.code == POBErrorNoAds) ? ERROR_IS_LOAD_NO_FILL : error.code;
    NSError *loadError = [NSError errorWithDomain:kAdapterName
                                             code:errorCode
                                                 userInfo:@{NSLocalizedDescriptionKey:error.description}];
    [self.delegate adapterInterstitialDidFailToLoadWithError:loadError];
}

/*!
 @abstract Notifies the delegate that the interstitial ad will be presented as a modal on top of the current view controller.
 @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialWillPresentAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/*!
 @abstract Notifies the delegate that the interstitial ad is presented as a modal on top of the current view controller.
 @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialDidPresentAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/**
 * @abstract Notifies the delegate that the interstitial ad has recorded the impression.
 *
 * @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialDidRecordImpression:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

/*!
 @abstract Notifies the delegate of an error encountered while showing an ad.
 @param interstitial The POBInterstitial instance sending the message.
 @param error The error encountered while showing an ad.
 */
- (void)interstitial:(POBInterstitial *)interstitial didFailToShowAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@, error = %@", self.adUnitId, error);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

/*!
 @abstract Notifies the delegate of ad click
 @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialDidClickAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClick];
}

/*!
 @abstract Notifies the delegate that a user interaction will open another app (e.g. App Store), leaving the current app. To handle user clicks that open the
 landing page URL in the internal browser, use 'interstitialDidClickAd:'
 instead.
 @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialWillLeaveApplication:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/*!
 @abstract Notifies the delegate that the interstitial ad has been animated off the screen.
 @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialDidDismissAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClose];
}

/*!
 @abstract Notifies the delegate of an ad expiration. After this callback, this 'POBInterstitial' instance is marked as invalid & will not be shown.
 @param interstitial The POBInterstitial instance sending the message.
 */
- (void)interstitialDidExpireAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

@end
