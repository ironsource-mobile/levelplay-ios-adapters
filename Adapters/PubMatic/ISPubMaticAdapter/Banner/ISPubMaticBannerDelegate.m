//
//  ISPubMaticBannerDelegate.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticBannerDelegate.h"
#import "ISPubMaticBannerAdapter.h"

@implementation ISPubMaticBannerDelegate


- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                         adapter:(ISPubMaticAdapter *)adapter
                        andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

/*!
 @abstract Asks the delegate for a view controller instance to use for presenting modal views as a result of user interaction on an ad. Usual implementation may simply return self, if it is a view controller class.
 */
- (UIViewController *)bannerViewPresentationController {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    return [self.adapter topMostController];
}

/*!
 @abstract Notifies the delegate that an ad has been successfully loaded and rendered..
 @param bannerView The POBBannerView instance sending the message.
 */
- (void)bannerViewDidReceiveAd:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidLoad:bannerView];
}

/*!
 @abstract Notifies the delegate of an error encountered while loading or rendering an ad.
 @param bannerView The POBBannerView instance sending the message.
 @param error The error encountered while attempting to receive or render the
 ad.
 */
- (void)bannerView:(POBBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@, error = %@", self.adUnitId, error);
    
    if (error.code != POBErrorRenderError) {
        NSInteger errorCode = (error.code == POBErrorNoAds) ? ERROR_BN_LOAD_NO_FILL : error.code;
        NSError *loadError = [NSError errorWithDomain:kAdapterName
                                                 code:errorCode
                                             userInfo:@{NSLocalizedDescriptionKey:error.description}];
        [self.delegate adapterBannerDidFailToLoadWithError:loadError];
    } else {
        NSError *showError = [NSError errorWithDomain:kAdapterName
                                                 code:error.code
                                             userInfo:@{NSLocalizedDescriptionKey:error.description}];
        [self.delegate adapterBannerDidFailToShowWithError:showError];
    }
}

/**
 * @abstract Notifies the delegate that the banner ad has recorded the impression.
 * @param bannerView The POBBannerView instance sending the message.
 */
- (void)bannerViewDidRecordImpression:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidShow];
}

/*!
 @abstract Notifies the delegate that the banner view was clicked.
 @param bannerView The POBBannerView instance sending the message.
 */
- (void)bannerViewDidClickAd:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidClick];
}

/*!
 @abstract Notifies the delegate whenever current app goes in the background due to user click.
 @param bannerView The POBBannerView instance sending the message.
 */
- (void)bannerViewWillLeaveApplication:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerWillLeaveApplication];
}

/*!
 @abstract Notifies delegate that the banner view will launch a modal on top of the current view controller, as a result of user interaction.
 @param bannerView The POBBannerView instance sending the message.
 */
- (void)bannerViewWillPresentModal:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerWillPresentScreen];
}

/*!
 @abstract Notifies delegate that the banner view has dismissed the modal on top of
 the current view controller.
 @param bannerView The POBBannerView instance sending the message.
 */
- (void)bannerViewDidDismissModal:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidDismissScreen];
}

@end
