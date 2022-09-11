//
//  ISYahooInterstitialDelegate.m
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISYahooInterstitialDelegate.h"

@implementation ISYahooInterstitialDelegate : NSObject

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISYahooInterstitialDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark - YASInterstitialAdDelegate Delegates

/**
 Called when the YASInterstitialAd has been successfully fetched and its content loaded
 in preparation for display. Note that this method is only called when ad fetching
 and loading is performed via the asynchronous -[YASInterstitialAd loadWithPlacementConfig:]
 method.
 
 @param interstitialAd    The YASInterstitialAd that was loaded.
 */
- (void)interstitialAdDidLoad:(nonnull YASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidLoad:_placementId
                  withInterstitialAd:interstitialAd];
}

/**
 Called when an error occurs during the YASInterstitialAd fetch and load lifecycle.
 A YASErrorInfo object provides detail about the error. Note that this method is only
 called when ad fetching and loading is performed via the asynchronous
 -[YASInterstitialAd loadWithPlacementConfig:] method.
 
 @param interstitialAd    The YASInterstitialAd that experienced the error.
 @param errorInfo         The YASErrorInfo that describes the error that occurred.
 */
- (void)interstitialAdLoadDidFail:(nonnull YASInterstitialAd *)interstitialAd
                        withError:(nonnull YASErrorInfo *)errorInfo {
    [_delegate onInterstitialDidFailToLoad:_placementId
                                 withError:errorInfo];
}

/**
 Called when the YASInterstitialAd has been shown.
 
 @param interstitialAd    The YASInterstitialAd that was shown.
 */
- (void)interstitialAdDidShow:(nonnull YASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidOpen:_placementId];
}

/**
 Called when an error occurs during the YASInterstitialAd lifecycle. A YASErrorInfo object provides detail about the error.
 
 @param interstitialAd    The YASInterstitialAd that experienced the error.
 @param errorInfo         The YASErrorInfo that describes the error that occurred.
 */
- (void)interstitialAdDidFail:(nonnull YASInterstitialAd *)interstitialAd
                    withError:(nonnull YASErrorInfo *)errorInfo {
    [_delegate onInterstitialShowFail:_placementId
                            withError:errorInfo];
}

/**
 Called when the YASInterstitialAd has been clicked.
 
 @param interstitialAd    The YASInterstitialAd that was clicked.
 */
- (void)interstitialAdClicked:(nonnull YASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidClick:_placementId];
}

/**
 Called when the YASInterstitialAd has been closed.
 
 @param interstitialAd    The YASInterstitialAd that was closed.
 */
- (void)interstitialAdDidClose:(nonnull YASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidClose:_placementId];
}

/**
 Called when the YASInterstitialAd causes the user to leave the application. For example, tapping a YASInterstitialAd may launch an external browser.
 
 @param interstitialAd    The YASInterstitialAd that caused the application exit.
 */
- (void)interstitialAdDidLeaveApplication:(nonnull YASInterstitialAd *)interstitialAd {
}

/**
 This callback is used to surface additional events to the publisher from the SDK.
 
 @param interstitialAd The YASInterstitialAd that is relaying the event.
 @param source         The identifier of the event source.
 @param eventId        The event identifier.
 @param arguments      A dictionary of key/value pairs of arguments related to the event.
 */
- (void)interstitialAdEvent:(nonnull YASInterstitialAd *)interstitialAd
                     source:(nonnull NSString *)source
                    eventId:(nonnull NSString *)eventId
                  arguments:(nullable NSDictionary<NSString *, id> *)arguments {
}

@end
